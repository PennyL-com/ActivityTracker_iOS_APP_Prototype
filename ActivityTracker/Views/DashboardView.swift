import SwiftUI
import CoreData
import Foundation

/// 主仪表板视图 - 显示所有活动的列表和管理界面
struct DashboardView: View {
    // MARK: - 状态变量
    @State private var showAdd = false // 控制是否显示添加活动的弹出视图
    @State private var showEdit: Activity? // 当前要编辑的活动，nil表示不显示编辑界面
    @State private var selectedActivity: Activity? = nil // 当前选中的活动（用于查看详情）
    let manager = ActivityDataManager.shared // 活动数据管理器单例实例
    
    // 使用 @FetchRequest 自动获取和监听 Core Data 数据
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Activity.createdDate, ascending: false)],
        animation: .default
    ) private var activities: FetchedResults<Activity>
    
    // 获取 Core Data 上下文
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                headerView
                activityListView
                Spacer()
                addButtonView
            }
            .sheet(isPresented: $showAdd) {
                AddActivityView(onSave: {}) // @FetchRequest 会自动更新，不需要手动刷新
            }
            .sheet(item: $showEdit) { activity in
                EditActivityView(activity: activity, onSave: {}) // @FetchRequest 会自动更新
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Okie dokie, let's start it!")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 16)
            
            // 添加测试按钮
            Button("Test Create Activity") {
                let testActivity = ActivityDataManager.shared.createActivity(
                    name: "Test Activity \(Date().timeIntervalSince1970)",
                    category: "Test",
                    iconName: "star",
                    optionalDetails: "Test activity created at \(Date())",
                    createdDate: Date(),
                    isCompleted: false
                )
                print("Test activity created: \(testActivity.name ?? "unnamed")")
            }
            
            Button("Test Fetch Activities") {
                let activities = ActivityDataManager.shared.fetchActivities()
                print("Manual fetch found \(activities.count) activities")
            }
            .font(.caption)
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var activityListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 添加调试信息
                Text("Activities count: \(activities.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                if activities.isEmpty {
                    Text("No activities found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(activities) { activity in
                        activityCardView(for: activity)
                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            print("DashboardView appeared, activities count: \(activities.count)")
            // 打印所有活动的名称用于调试
            for (index, activity) in activities.enumerated() {
                print("Activity \(index): \(activity.name ?? "unnamed")")
            }
        }
    }

    @ViewBuilder
    private func activityCardView(for activity: Activity) -> some View {
        // 这里填原来 ForEach 里的内容
        // 获取活动的完成记录集合 TODO：什么叫completion？干嘛用的为啥一个activity有好几个completions
        let completions = (activity.completions as? Set<Completion>) ?? []
        // 检查今天是否已完成该活动
        let isCompletedToday = completions.contains { completion in
            if let date = completion.completedDate {
                let isToday = Calendar.current.isDateInToday(date)
                // 添加调试信息，帮助排查问题
                print("Activity: \(activity.name ?? ""), completion date: \(date), isToday: \(isToday)")
                return isToday
            }
            return false
        }
        ActivityCardView(
            activity: activity,
            onComplete: {
                _ = manager.addCompletion(to: activity, source: "app")
                // @FetchRequest 会自动更新，不需要手动刷新
            },
            onEdit: {
                showEdit = activity
            },
            onDelete: {
                manager.deleteActivity(activity)
                // @FetchRequest 会自动更新，不需要手动刷新
            },
            onTapCard: {
                selectedActivity = activity
            },
            onTapCheck: { // 点击打钩按钮事件在这里
                activity.isCompleted = true
                manager.save() // 保存到 Core Data
                // @FetchRequest 会自动更新，不需要手动刷新
            }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                manager.deleteActivity(activity)
                // @FetchRequest 会自动更新，不需要手动刷新
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var addButtonView: some View {
        Button(action: { showAdd = true }) {
            HStack {
                Image(systemName: "plus")
                Text(LocalizedStringKey("Add Activity"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .padding([.horizontal, .bottom])
    }

    /// 计算活动自上次完成以来经过的天数
    /// - Parameter activity: 要计算的活动
    /// - Returns: 天数，如果没有完成记录则返回 -1
    //TODO：这个方法在ActivityCardView中也有，应该抽取一个函数
    func daysSinceLastCompletion(activity: Activity) -> Int {
        let completions = manager.fetchCompletions(for: activity) // 获取活动的完成记录
        guard let last = completions.first?.completedDate else { return -1 } // 如果没有完成记录返回 -1
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? -1 // 计算天数差
    }
}

/// SwiftUI 预览
#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext) // 使用预览环境
} 
