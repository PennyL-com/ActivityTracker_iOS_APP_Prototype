import SwiftUI

struct NilCategoryActivitiesView: View {
    @State private var activities: [Activity] = []
    @State private var selectedActivity: Activity? = nil

    // 排序：将选中的活动置顶
    private func sortActivityToTop(_ activity: Activity) {
        guard let index = activities.firstIndex(of: activity) else { return }
        activities.remove(at: index)
        activities.insert(activity, at: 0)
        
        // 同步到CoreData的sortOrder字段
        // 获取当前所有未分类活动的最大sortOrder值
        let maxSortOrder = activities.map { $0.sortOrder }.max() ?? -1
        activity.sortOrder = maxSortOrder + 1
        
        // 保存到Core Data
        ActivityDataManager.shared.save()
    }

    // 删除活动
    private func deleteActivity(_ activity: Activity) {
        ActivityDataManager.shared.deleteActivity(activity)
        activities.removeAll { $0 == activity }
    }

    // 完成活动（打钩）
    private func completeActivity(_ activity: Activity) {
        _ = ActivityDataManager.shared.addCompletion(to: activity, completedDate: Date(), source: "app")
        // 立即刷新，保证UI同步
        activities = ActivityDataManager.shared.fetchActivitiesWithNilCategory()
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(activities, id: \.self) { activity in
                    ActivityCardView(
                        activity: activity,
                        onComplete: { completeActivity(activity) },
                        onDelete: { deleteActivity(activity) },
                        onTapCard: { selectedActivity = activity },
                        onSort: { sortActivityToTop(activity) },
                        showSort: false // 只显示删除按钮，隐藏排序按钮
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Uncategorized Activities")
            .onAppear {
                activities = ActivityDataManager.shared.fetchActivitiesWithNilCategory()
            }
            .background(
                NavigationLink(
                    destination: selectedActivity.map { ActivityDetailView(activity: $0) },
                    isActive: Binding(
                        get: { selectedActivity != nil },
                        set: { if !$0 { selectedActivity = nil } }
                    )
                ) { EmptyView() }
                .hidden()
            )
        }
    }
}

// 预览
#Preview {
    NilCategoryActivitiesView()
} 