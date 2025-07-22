import SwiftUI
import CoreData
import Foundation

/// 主仪表板视图 - 显示所有活动的列表和管理界面
struct DashboardView: View {
    // MARK: - 状态变量
    @State private var showAdd = false // 控制是否显示添加活动的弹出视图
    @State private var selectedActivity: Activity? = nil // 当前选中的活动（用于查看详情）
    @State private var showTestDataAlert = false // 控制是否显示测试数据确认对话框
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
            .sheet(item: $selectedActivity) { activity in
                NavigationView {
                    ActivityDetailView(activity: activity)
                }
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("测试数据") {
                        showTestDataAlert = true
                    }
                    .font(.caption)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CalendarView()) {
                        Image(systemName: "calendar")
                            .font(.title2)
                    }
                }
            }
            .alert("生成测试数据", isPresented: $showTestDataAlert) {
                Button("生成") {
                    TestDataGenerator.generateSampleData(context: viewContext)
                }
                Button("清除所有数据") {
                    TestDataGenerator.clearAllData(context: viewContext)
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("这将生成一些示例活动和完成记录来演示日历功能")
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Okie dokie, let's start it!")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 16)
        }
    }

    private var activityListView: some View {
        List {
            ForEach(activities) { activity in
                activityCardView(for: activity)
                    .listRowSeparator(.hidden) // 可选：隐藏分割线
                    .listRowBackground(Color.clear) // 可选：透明背景
            }
        }
        .listStyle(.plain) // 可选：去除多余样式
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
                if !isCompletedToday {
                    let newCompletion = Completion(context: viewContext)
                    newCompletion.id = UUID()
                    newCompletion.completedDate = Date()
                    newCompletion.source = "app"
                    newCompletion.activity = activity
                    do {
                        try viewContext.save()
                    } catch {
                        print("保存完成记录失败: \(error)")
                    }
                    // 额外回调
                    manager.save()
                }
            },
            onDelete: {
                manager.deleteActivity(activity)
                // @FetchRequest 会自动更新，不需要手动刷新
            },
            onTapCard: {
                selectedActivity = activity
            },
        )
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
}

/// SwiftUI 预览
#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext) // 使用预览环境
} 
