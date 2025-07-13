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
                // 顶部标题
                Text("Okie dokie, let's start it!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                
                // 活动列表滚动视图
                ScrollView {
                    VStack(spacing: 16) {
                        // 遍历所有活动，为每个活动创建卡片视图
                        ForEach(activities, id: \.id) { activity in
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
                            
                            // 活动卡片视图
                            ActivityCardView(
                                activity: activity, // 当前活动对象
                                isCompletedToday: isCompletedToday, // 今天是否已完成
                                onComplete: {
                                    // 完成活动的回调：添加完成记录并刷新列表
                                    _ = manager.addCompletion(to: activity, source: "app")
                                    reload()
                                },
                                onEdit: {// CardView定义长按卡片可以编辑
                                    // 编辑活动的回调：设置要编辑的活动
                                    showEdit = activity
                                },
                                onDelete: {
                                    // 删除活动的回调：删除活动并刷新列表
                                    manager.deleteActivity(activity)
                                    reload()
                                },
                                onTapCard: {//TODO：主要问题（打钩按钮是属于卡片的在更内层，这一层定义了卡片的点击时间，回覆盖点击内层按钮导致点不着。 Action：尝试把Vstack调用的.sheet挪到cardView后面）
                                    // 点击卡片的回调：设置选中的活动用于查看详情
                                    selectedActivity = activity
                                }//Action：添加一个按钮点击方法
                            )
                            // 添加滑动删除功能 TODO：这个滑动功能不管用，不知道在哪被截断了
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    // 滑动删除：删除活动并刷新列表
                                    manager.deleteActivity(activity)
                                    reload()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal) // 只在左右两边添加内边距
                }
                
                Spacer() // 弹性空间，将按钮推到底部
                
                // 添加活动按钮
                Button(action: { showAdd = true }) {//变成true时表示弹出添加活动view
                    HStack {
                        Image(systemName: "plus") // 加号图标
                        Text(LocalizedStringKey("Add Activity")) // 本地化文本
                    }
                    .frame(maxWidth: .infinity) // 占满宽度
                    .padding() 
                    .background(Color.accentColor) // 背景色
                    .foregroundColor(.white) // 文字颜色
                    .cornerRadius(16) // 圆角
                }
                .padding([.horizontal, .bottom]) // 外边距
            }
            // 添加活动弹出视图
            .sheet(isPresented: $showAdd, onDismiss: reload) {// 按下按钮后showAdd变成true
                AddActivityView(onSave: reload) // 保存时刷新列表
            }
            // 编辑活动弹出视图 TODO：没有调用这个方法的地方
            .sheet(item: $showEdit, onDismiss: reload) { activity in
                EditActivityView(activity: activity, onSave: reload) // 保存时刷新列表
            }
            // 活动详情弹出视图
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity) // 显示活动详情
            }
            .onAppear(perform: reload) // 视图出现时加载数据
            .background(Color(.systemGray6).ignoresSafeArea()) // 背景色
        }
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