import SwiftUI
import CoreData

struct CategoriesDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    ) var categories: FetchedResults<Category>
    @State private var selectedCategory: Category? = nil
    @State private var showCategoryDetail = false
    @State private var isDeleteMode = false // 新增：控制删除模式
    
    // 获取所有完成记录的日期
    private var allCompletionDates: [Date] {
        let activities = ActivityDataManager.shared.fetchActivities()
        var allCompletions: [Completion] = []
        for activity in activities {
            if let completions = activity.completions as? Set<Completion> {
                allCompletions.append(contentsOf: completions)
            }
        }
        return allCompletions.compactMap { $0.completedDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 页面标题
            Text("Overview")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 24)
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
            // 日历分组（固定在顶部）
            HStack {
                Spacer(minLength: 0)
                CalendarView(
                    externalCompletionDates: allCompletionDates
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
            )
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 12)
            // 分类分组（可滚动）
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("所有分类")
                        .font(.headline)
                    Spacer()
                    Button(action: { showAddCategory = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.trailing, 8) // 加号按钮左移
                    .disabled(isDeleteMode) // 删除模式下禁用加号按钮
                    Button(action: { isDeleteMode.toggle() }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(isDeleteMode ? .mint : .red)
                    }
                    .accessibilityLabel("删除类别")
                }
                // 分类按钮网格区域可滚动
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(categories) { category in
                            ZStack(alignment: .topTrailing) {
                                Button(action: {
                                    if !isDeleteMode {
                                        selectedCategory = category
                                        showCategoryDetail = true
                                    }
                                }) {
                                    Text(category.name ?? "-")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(Color(.systemBackground))
                                                .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
                                        )
                                }
                                if isDeleteMode {
                                    Button(action: {
                                        // 删除类别但不删除相关活动
                                        ActivityDataManager.shared.deleteCategory(category)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .background(Color.white.clipShape(Circle()))
                                            .padding(2)
                                    }
                                    .offset(x: 6, y: -6)
                                    .zIndex(1)
                                }
                            }
                            .padding(6)
                        }
                    }
                }
                .frame(maxHeight: 350) // 设置最大高度，超出可滚动
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
            )
            .padding(.horizontal)
            .padding(.bottom, 24)
            Spacer() // 拉伸到底部
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGray6).ignoresSafeArea())
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet(
                newCategoryName: $newCategoryName,
                onConfirm: {
                    if !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                        _ = ActivityDataManager.shared.createCategory(name: newCategoryName)
                        newCategoryName = ""
                        showAddCategory = false
                    }
                },
                onCancel: {
                    showAddCategory = false
                    newCategoryName = ""
                }
            )
        }
        .onAppear {
            ActivityDataManager.shared.ensureDefaultCategories()
        }
        .sheet(item: $selectedCategory) { category in
            CategoryDetailView(category: category)
        }
    }
}

// 预览
#Preview {
    CategoriesDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 