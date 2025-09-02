import SwiftUI
import CoreData

struct CategoriesDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    ) var categories: FetchedResults<Category>

    private enum CategoryFilter: Hashable { case all, uncategorized, category(UUID) }

    @State private var selectedFilter: CategoryFilter = .all
    @State private var selectedActivity: Activity? = nil
    @State private var refreshTrigger = UUID()
    @State private var scrollOffset: CGFloat = 0
    private let manager = ActivityDataManager.shared

    // 根据筛选条件获取活动
    private var filteredActivities: [Activity] {
        switch selectedFilter {
        case .all:
            return manager.fetchActivities()
        case .uncategorized:
            return manager.fetchActivitiesWithNilCategory()
        case .category(let id):
            if let category = categories.first(where: { $0.categoryId == id }) {
                return manager.fetchActivities(for: category)
            }
            return []
        }
    }

    // 根据筛选条件聚合完成日期，用于日历显示
    private var filteredCompletionDates: [Date] {
        var all: [Date] = []
        for activity in filteredActivities {
            if let comps = activity.completions as? Set<Completion> {
                all.append(contentsOf: comps.compactMap { $0.completedDate })
            }
        }
        return all
    }

    // 当前筛选标题
    private var selectedFilterTitle: String {
        switch selectedFilter {
        case .all:
            return "All"
        case .uncategorized:
            return "Uncategorized"
        case .category(let id):
            return categories.first(where: { $0.categoryId == id })?.name ?? "Category"
        }
    }

    // 计算日历透明度（滚动时淡出）
    private var calendarOpacity: Double {
        let start: CGFloat = 0
        let end: CGFloat = 120 // 调整淡出范围
        let progress = max(0, min(1, (scrollOffset - start) / (end - start)))
        return Double(1 - progress)
    }

    var body: some View {
        VStack(spacing: 12) {
            // 顶部筛选
            HStack(spacing: 12) {
                Text("Filter")
                    .font(.headline)
                Spacer()
                Menu {
                    Button(action: { selectedFilter = .all }) {
                        Label("All", systemImage: selectedFilter == .all ? "checkmark" : "")
                    }
                    Button(action: { selectedFilter = .uncategorized }) {
                        Label("Uncategorized", systemImage: selectedFilter == .uncategorized ? "checkmark" : "")
                    }
                    Divider()
                    ForEach(categories) { category in
                        Button(action: { if let id = category.categoryId { selectedFilter = .category(id) } }) {
                            Label(category.name ?? "-", systemImage: {
                                if case .category(let id) = selectedFilter, id == category.categoryId { return "checkmark" }
                                return ""
                            }())
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(selectedFilterTitle)
                    }
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
            }
            .padding()
            .frame(maxWidth: 520)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
            )
            .padding(.top, 20)
            .padding(.horizontal)

            // 可滚动区域：日历 + 活动列表
            ScrollView(.vertical, showsIndicators: true) {
                // 顶部锚点用于计算偏移
                Color.clear
                    .frame(height: 0)
                    .background(
                        GeometryReader { proxy in
                            let y = -proxy.frame(in: .named("categoriesScroll")).origin.y
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: y)
                        }
                    )

                // 日历
                HStack {
                    Spacer(minLength: 0)
                    CalendarView(
                        externalCompletionDates: filteredCompletionDates
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
                )
                .padding(.horizontal)
                .opacity(calendarOpacity)

                // 活动列表（LazyVStack 可滚动）
                LazyVStack(spacing: 12) {
                    if filteredActivities.isEmpty {
                        Text("No activities")
                            .foregroundColor(.secondary)
                            .padding(.top, 12)
                    } else {
                        ForEach(filteredActivities) { activity in
                            activityCard(for: activity)
                                .padding(.horizontal)
                        }
                        .id(refreshTrigger)
                    }
                }
                .padding(.vertical, 8)
            }
            .coordinateSpace(name: "categoriesScroll")

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGray6).ignoresSafeArea())
        .onAppear {
            manager.ensureDefaultCategories()
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailView(activity: activity)
        }
    }

    @ViewBuilder
    private func activityCard(for activity: Activity) -> some View {
        let completions = (activity.completions as? Set<Completion>) ?? []
        let isCompletedToday = completions.contains { comp in
            if let date = comp.completedDate {
                return Calendar.current.isDateInToday(date)
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
                        manager.forceRefreshWidget()
                        refreshTrigger = UUID()
                    } catch {
                        print("保存完成记录失败: \(error)")
                    }
                    manager.save()
                }
            },
            onDelete: {
                manager.deleteActivity(activity)
                refreshTrigger = UUID()
            },
            onTapCard: {
                selectedActivity = activity
            },
            onSort: {},
            showSort: false
        )
    }
}

// MARK: - 滚动偏移 PreferenceKey
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 预览
#Preview {
    CategoriesDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
