import SwiftUI
import CoreData


struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var category: Category? = nil
    @State private var optionalDetails = ""
    @State private var selectedEmoji: String = ""
    @State private var showEmojiPicker = false
    // 多选日历相关状态
    @State private var selectedDates: [Date] = []
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    ) var categories: FetchedResults<Category>
    var onSave: () -> Void
    var defaultCategory: Category? = nil
    
    init(onSave: @escaping () -> Void, defaultCategory: Category? = nil) {
        self.onSave = onSave
        self._category = State(initialValue: defaultCategory)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 基本信息分组
                        VStack(spacing: 12) {
                            TextField("Name", text: $name)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            HStack {
                                Text("Category")
                                Spacer()
                                CategoryPickerView(selection: $category)
                            }
                            HStack {
                                Text("Select Icon")
                                Spacer()
                                Button(action: {
                                    showEmojiPicker = true
                                }) {
                                    Text(selectedEmoji.isEmpty ? "" : selectedEmoji)
                                        .font(.largeTitle)
                                        .frame(width: 44, height: 44)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(8)
                                }
                            }
                            .sheet(isPresented: $showEmojiPicker) {
                                IconPickerView(
                                    selectedEmoji: $selectedEmoji,
                                    onSelect: { showEmojiPicker = false }
                                )
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextEditor(text: $optionalDetails)
                                    .frame(minHeight: 40, maxHeight: 200)
                                    .padding(2)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
                        )

                        // 历史日历分组
                        HistoryCalendarSection(
                            selectedDates: $selectedDates
                        )
                        Spacer(minLength: 0)
                    }
                    .padding()
                }
                // 固定底部的保存按钮
                Button(action: {
                    guard let selectedCategory = category else { return }
                    let activity = ActivityDataManager.shared.createActivity(
                        name: name,
                        category: selectedCategory,
                        iconName: selectedEmoji,
                        optionalDetails: optionalDetails.isEmpty ? nil : optionalDetails,
                        createdDate: Date(),
                        isCompleted: false
                    )
                    for date in selectedDates {
                        ActivityDataManager.shared.addCompletion(to: activity, completedDate: date, source: "app")
                    }
                    onSave()
                    presentationMode.wrappedValue.dismiss()
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
                .disabled(name.isEmpty || category == nil || selectedEmoji.isEmpty)
                .padding(.bottom, 12)
            }
            .navigationTitle("Add Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.font(.title3)
                }
            }
        }
    }
    // 日期格式化辅助函数
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

// 历史日历分组
struct HistoryCalendarSection: View {
    @Binding var selectedDates: [Date]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose history completion dates:")
                .foregroundColor(.secondary)
                .font(.footnote)
            CalendarView(
                isEditing: true,
                pendingAddDates: Binding(get: { Set(selectedDates) }, set: { newDates in
                    // 简化的日期校验：只检查不能选择未来日期
                    let maxDate = Calendar.current.startOfDay(for: Date())
                    let invalidDates = newDates.filter { $0 > maxDate }
                    if !invalidDates.isEmpty {
                        // 过滤掉未来日期，只保留有效日期
                        let validDates = newDates.filter { $0 <= maxDate }
                        selectedDates = Array(validDates)
                    } else {
                        selectedDates = Array(newDates)
                    }
                }),
                isBlankCalendar: true
            )
            .frame(height: 320)
            if !selectedDates.isEmpty {
                Text("Selected dates: \(selectedDates.map { formatDate($0) }.joined(separator: ", "))")
                    .font(.footnote)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
    // 日期格式化辅助函数
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

#Preview {
    AddActivityView(onSave: {})
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
