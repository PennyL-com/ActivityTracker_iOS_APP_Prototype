import SwiftUI
import CoreData

struct CategoryDetailView: View {
    let category: Category
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest var activities: FetchedResults<Activity>
    @State private var completions: [Completion] = []
    @State private var showAddActivity = false
    @State private var showEditCategory = false
    @State private var isEditing = false // 编辑模式
    @State private var isSorting = false // 新增：排序模式
    @State private var sortActivities: [Activity] = [] // 新增：排序用本地数组
    @State private var showDuplicateAlert = false // 新增：重名Alert
    @State private var showEmptyAlert = false // 新增：空名Alert
    @State private var editingName: String = "" // 新增：编辑中的名字

    // 该分类下所有活动的完成日期
    private var categoryCompletionDates: [Date] {
        var allCompletions: [Completion] = []
        for activity in activities {
            if let completionSet = activity.completions as? Set<Completion> {
                let completionsArray: [Completion] = Array(completionSet)
                allCompletions.append(contentsOf: completionsArray)
            }
        }
        let dates: [Date] = allCompletions.compactMap { $0.completedDate }
        return dates
    }

    // 检查分类名是否重复（排除当前分类）
    private func isDuplicateCategoryName(_ name: String) -> Bool {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND self != %@", name, category)
        let count = (try? viewContext.count(for: fetchRequest)) ?? 0
        return count > 0
    }

    // 新增：保存分类名时的校验逻辑
    private func trySaveCategoryName(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            showEmptyAlert = true
            return
        }
        if isDuplicateCategoryName(trimmed) {
            showDuplicateAlert = true
            return
        }
        category.name = trimmed
        try? viewContext.save()
        isEditing = false
    }

    private var activityListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("该分类下的活动（滑动查看详情）")
                    .font(.headline)
                    .padding(.horizontal)
                Spacer()
                Button(action: { showAddActivity = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .disabled(isEditing) // 编辑状态下禁用添加按钮
            }
            Group {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(activities) { activity in
                            NavigationLink(
                                destination: ActivityDetailView(activity: activity),
                                label: {
                                    activityCardView(for: activity, showSort: true)
                                }
                            )
                            .disabled(isEditing) // 编辑模式下禁用跳转
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .onAppear {
                if isSorting {
                    sortActivities = Array(activities)
                }
            }
        }
        .padding(.horizontal)
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
            let completions = (activity.completions as? Set<Completion>) ?? []
            let isCompletedToday = completions.contains { completion in
                if let date = completion.completedDate {
                    return Calendar.current.isDateInToday(date)
                }
                return false
            }
            HStack(spacing: 0) {
                ActivityCardView(
                    activity: activity,
                    onComplete: {
                        if !isCompletedToday && !isEditing {
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
                            // activities 会自动刷新，无需手动赋值
                        }
                    },
                    onDelete: {
                        ActivityDataManager.shared.deleteActivity(activity)
                        // activities 会自动刷新，无需手动赋值
                    },
                    onTapCard: {
                        // 跳转到ActivityDetailView
                    },
                    onSort: {
                        if !isSorting {
                            sortActivities = Array(activities)
                            isSorting = true
                        }
                    },
                    showSort: showSort
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                // 解绑按钮已移除
            }
        }
    }

    init(category: Category) {
        self.category = category
        // 初始化 FetchRequest，监听该分类下的活动
        _activities = FetchRequest(
            entity: Activity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Activity.createdDate, ascending: false)],
            predicate: NSPredicate(format: "belongToCategory == %@", category)
        )
        editingName = category.name ?? ""
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 大标题和编辑按钮
                HStack {
                    if isEditing {
                        HStack(spacing: 8) {
                            TextField("Tap in category name", text: $editingName)
                                .font(.system(size: 20, weight: .bold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            Image(systemName: "pencil")
                                .foregroundColor(.accentColor)
                        }
                    } else {
                        Text(category.name ?? "分类详情")
                            .font(.system(size: 20, weight: .bold))
                    }
                    Spacer()
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            trySaveCategoryName(editingName)
                        } else {
                            editingName = category.name ?? ""
                            isEditing = true
                        }
                    }
                    .disabled((category.name ?? "") == "Uncategorized") // Uncategorized分类禁用按钮
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                .padding(.horizontal, 30)
                // 日历卡片样式
                HStack {
                    Spacer(minLength: 0)
                    CalendarView(
                        externalCompletionDates: categoryCompletionDates
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                // 活动卡片列表
                activityListView
                Spacer()
            }
        }
        .navigationTitle(category.name ?? "分类详情")
        .background(Color(.systemGray6).ignoresSafeArea())
        .sheet(isPresented: $showAddActivity) {
            AddActivityView(
                onSave: {
                    /* activities 会自动刷新，无需手动赋值 */
                },
                defaultCategory: category // 传递当前分类
            )
        }
        // 新增：重名Alert
        .alert("分类名已存在", isPresented: $showDuplicateAlert) {
            Button("确定", role: .cancel) { }
        }
        // 新增：空名Alert
        .alert("分类名不能为空或全空格", isPresented: $showEmptyAlert) {
            Button("确定", role: .cancel) { }
        }
    }
}

// 预览
#Preview {
    let context = PersistenceController.preview.container.viewContext
    let category = Category(context: context)
    category.categoryId = UUID()
    category.name = "Wellness"
    return CategoryDetailView(category: category)
        .environment(\.managedObjectContext, context)
} 