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
    @State private var activities: [Activity] = [] // 当前显示的活动列表

    /// 重新加载活动数据
    /// 从 Core Data 中获取最新的活动列表并更新 UI
    private func reload() {
        activities = manager.fetchActivities() // 从数据管理器获取所有活动
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                headerView
                activityListView
                Spacer()
                addButtonView
            }
            .sheet(isPresented: $showAdd, onDismiss: reload) {
                AddActivityView(onSave: reload)
            }
            .sheet(item: $showEdit, onDismiss: reload) { activity in
                EditActivityView(activity: activity, onSave: reload)
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
            .onAppear(perform: reload)
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }

    private var headerView: some View {
        Text("Okie dokie, let's start it!")
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top, 16)
    }

    private var activityListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(activities, id: \.id) { activity in
                    activityCardView(for: activity)
                }
            }
            .padding(.horizontal)
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
            isCompletedToday: isCompletedToday,
            onComplete: {
                _ = manager.addCompletion(to: activity, source: "app")
                reload()
            },
            onEdit: {
                showEdit = activity
            },
            onDelete: {
                manager.deleteActivity(activity)
                reload()
            },
            onTapCard: {
                selectedActivity = activity
            },
            onTapCheck: {
                activity.isCompleted = true 
                reload()
            }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                manager.deleteActivity(activity)
                reload()
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
