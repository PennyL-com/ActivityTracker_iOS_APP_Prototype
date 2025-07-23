import SwiftUI
import CoreData
import Foundation

/// 主仪表板视图 - 显示所有活动的列表和管理界面
struct DashboardView: View {
    // MARK: - 状态变量
    @State private var showAdd = false // 控制是否显示添加活动的弹出视图
    @State private var selectedActivity: Activity? = nil // 当前选中的活动（用于查看详情）
    @State private var isSorting = false // 是否处于排序模式
    @State private var sortActivities: [Activity] = [] // 排序模式下的本地活动数组
    let manager = ActivityDataManager.shared // 活动数据管理器单例实例
    
    // 使用 @FetchRequest 自动获取和监听 Core Data 数据
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Activity.sortOrder, ascending: true)],
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
                    if isSorting {
                        Button("保存") {
                            saveSortOrder()
                        }
                        .font(.caption)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CalendarView()) {
                        Image(systemName: "calendar")
                            .font(.title2)
                    }
                }
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
        Group {
            if isSorting {
                List {
                    ForEach(sortActivities, id: \.id) { activity in
                        activityCardView(for: activity, showSort: false)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .onMove(perform: moveActivity)
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
            } else {
                List {
                    ForEach(activities) { activity in
                        activityCardView(for: activity, showSort: true)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            if isSorting {
                sortActivities = activities.map { $0 }
            }
        }
    }

    @ViewBuilder
    private func activityCardView(for activity: Activity, showSort: Bool) -> some View {
        if isSorting {
            // 排序模式下只显示icon和name，极简渲染，不显示任何按钮
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 48, height: 48)
                    if let icon = activity.iconName, icon.isSingleEmoji {
                        Text(icon)
                            .font(.system(size: 28))
                    } else {
                        Image(systemName: activity.iconName ?? "circle")
                            .font(.system(size: 28))
                    }
                }
                Text(activity.name ?? "")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: Color(.black).opacity(0.04), radius: 6, x: 0, y: 2)
        } else {
            // 普通模式下完整卡片
            let completions = (activity.completions as? Set<Completion>) ?? []
            let isCompletedToday = completions.contains { completion in
                if let date = completion.completedDate {
                    let isToday = Calendar.current.isDateInToday(date)
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
                        manager.save()
                    }
                },
                onDelete: {
                    manager.deleteActivity(activity)
                },
                onTapCard: {
                    selectedActivity = activity
                },
                onSort: {
                    if !isSorting {
                        sortActivities = activities.map { $0 }
                        isSorting = true
                    }
                },
                showSort: showSort
            )
        }
    }

    private func moveActivity(from source: IndexSet, to destination: Int) {
        sortActivities.move(fromOffsets: source, toOffset: destination)
    }

    private func saveSortOrder() {
        for (index, activity) in sortActivities.enumerated() {
            activity.setValue(Int64(index), forKey: "sortOrder")
        }
        do {
            try viewContext.save()
            isSorting = false
        } catch {
            print("保存排序失败: \(error)")
        }
    }

    private var addButtonView: some View {
        Group {
            if !isSorting {
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
    }
}

/// SwiftUI 预览
#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext) // 使用预览环境
} 
