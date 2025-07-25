import SwiftUI

struct ActivityDetailView: View {
    @ObservedObject var activity: Activity // 用于CoreData对象的UI响应
    let manager = ActivityDataManager.shared
    @State private var completions: [Completion] = []
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedCategory: Category? = nil
    @State private var editedNotes: String = ""
    @State private var showIconPicker = false
    @State private var editedIconName: String = ""
    @State private var pendingAddDates: Set<Date> = []
    @State private var pendingRemoveDates: Set<Date> = []
    @State private var categories: [Category] = []

    private func reload() {
        completions = manager.fetchCompletions(for: activity)
        categories = manager.fetchCategories()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // 活动详情分组
                    ActivityInfoSection(
                        activity: activity,
                        isEditing: $isEditing,
                        editedName: $editedName,
                        editedCategory: $editedCategory,
                        editedNotes: $editedNotes,
                        showIconPicker: $showIconPicker,
                        editedIconName: $editedIconName,
                        categories: categories
                    )
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
                    )

                    // 日历分组
                    ActivityCalendarSection(
                        isEditing: isEditing,
                        completions: completions,
                        pendingAddDates: $pendingAddDates,
                        pendingRemoveDates: $pendingRemoveDates
                    )
                }
                .padding()
            }
            // 固定底部的保存按钮，仅在isEditing时显示
            if isEditing {
                Button(action: {
                    saveEdits()
                }) {
                    Text("Save")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.bottom, 12)
            }
        }
        .navigationTitle(activity.name ?? "Activity Detail")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Cancel") {
                        isEditing = false
                    }
                    .font(.title3)
                } else {
                    Button("Edit") {
                        editedName = activity.name ?? ""
                        editedCategory = activity.belongToCategory
                        editedNotes = activity.optionalDetails ?? ""
                        editedIconName = activity.iconName ?? ""
                        isEditing = true
                    }
                    .font(.title3)
                    .foregroundColor(Color.accentColor)
                }
            }
        }
        .onAppear {
            reload()
        }
    }

    private func saveEdits() {
        activity.name = editedName
        activity.belongToCategory = editedCategory
        activity.optionalDetails = editedNotes
        activity.iconName = editedIconName
        // 新增/删除Completion
        for date in pendingAddDates {
            manager.addCompletion(to: activity, completedDate: date, source: "app")
        }
        for date in pendingRemoveDates {
            if let completion = completions.first(where: { Calendar.current.isDate($0.completedDate ?? Date(), inSameDayAs: date) }) {
                manager.deleteCompletion(completion)
            }
        }
        pendingAddDates.removeAll()
        pendingRemoveDates.removeAll()
        do {
            try activity.managedObjectContext?.save()
            isEditing = false
            reload()
        } catch {
            print("Failed to save: \(error)")
        }
    }

    func daysSinceLastCompletion() -> Int {
        let completions = manager.fetchCompletions(for: activity)
        guard let last = completions.first?.completedDate else { return -1 }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? -1
    }

}

// 活动详情分组子视图
struct ActivityInfoSection: View {
    var activity: Activity
    @Binding var isEditing: Bool
    @Binding var editedName: String
    @Binding var editedCategory: Category?
    @Binding var editedNotes: String
    @Binding var showIconPicker: Bool
    @Binding var editedIconName: String
    var categories: [Category]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if isEditing {
                    Button(action: { showIconPicker = true }) {
                        if !editedIconName.isEmpty {
                            Text(editedIconName)
                                .font(.largeTitle)
                                .frame(width: 48, height: 48)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "circle")
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                                .frame(width: 48, height: 48)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .sheet(isPresented: $showIconPicker) {
                        IconPickerView(selectedEmoji: $editedIconName, onSelect: { showIconPicker = false })
                    }
                    TextField("Activity Name", text: $editedName)
                        .font(.title2)
                        .fontWeight(.bold)
                } else {
                    if let iconName = activity.iconName, !iconName.isEmpty {
                        if iconName.isSingleEmoji {
                            Text(iconName)
                                .font(.largeTitle)
                                .frame(width: 48, height: 48)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        } else {
                            Image(systemName: iconName)
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                                .frame(width: 48, height: 48)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    } else {
                        Image(systemName: "circle")
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                            .frame(width: 48, height: 48)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    Text(activity.name ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
            }
            HStack {
                Text("Category")
                    .foregroundColor(.secondary)
                Spacer()
                if isEditing {
                    CategoryPickerView(selection: $editedCategory)
                        .pickerStyle(MenuPickerStyle())
                } else {
                    Text(activity.belongToCategory?.name ?? "Uncategorized")
                }
            }
            if isEditing {
                VStack(alignment: .leading) {
                    Text("Details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $editedNotes)
                        .frame(minHeight: 40, maxHeight: 200)
                        .padding(2)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            } else if let notes = activity.optionalDetails, !notes.isEmpty {
                HStack(alignment: .top) {
                    Text("Description")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }
}

// 日历分组子视图
struct ActivityCalendarSection: View {
    var isEditing: Bool
    var completions: [Completion]
    @Binding var pendingAddDates: Set<Date>
    @Binding var pendingRemoveDates: Set<Date>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History Calendar")
                .font(.headline)
            if isEditing {
                CalendarView(
                    isEditing: true,
                    pendingAddDates: $pendingAddDates,
                    pendingRemoveDates: $pendingRemoveDates,
                    activityCompletionDates: completions.compactMap { $0.completedDate }
                )
                .frame(height: 300)
            } else {
                CalendarView(
                    activityCompletionDates: completions.compactMap { $0.completedDate }
                )
                .frame(height: 300)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    // 创建模拟分类
    let mockCategory = Category(context: context)
    mockCategory.categoryId = UUID()
    mockCategory.name = "Health"
    // 创建模拟活动
    let mockActivity = Activity(context: context)
    mockActivity.id = UUID()
    mockActivity.name = "Sample Activity"
    mockActivity.belongToCategory = mockCategory
    mockActivity.optionalDetails = "This is a sample activity for preview"
    mockActivity.createdDate = Date()
    // 添加一些模拟的完成记录
    let completion1 = Completion(context: context)
    completion1.id = UUID()
    completion1.completedDate = Date()
    completion1.source = "app"
    completion1.activity = mockActivity
    let completion2 = Completion(context: context)
    completion2.id = UUID()
    completion2.completedDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    completion2.source = "widget"
    completion2.activity = mockActivity
    return ActivityDetailView(activity: mockActivity)
        .environment(\.managedObjectContext, context)
} 