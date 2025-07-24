import SwiftUI
import CoreData


struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var category: Category? = nil
    @State private var optionalDetails = ""
    @State private var selectedEmoji: String = ""
    @State private var showEmojiPicker = false
    // 新增：起始日期和多选日历相关状态
    @State private var startFromDate = Date()
    @State private var showCalendarInline = false
    @State private var selectedDates: [Date] = []
    // 新增：非法日期弹窗相关状态
    @State private var showInvalidDateAlert = false
    @State private var invalidDateMessage = ""
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    ) var categories: FetchedResults<Category>
    var onSave: () -> Void
    
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
                            startFromDate: $startFromDate,
                            selectedDates: $selectedDates,
                            showInvalidDateAlert: $showInvalidDateAlert,
                            invalidDateMessage: $invalidDateMessage
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
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(name.isEmpty || selectedDates.isEmpty || category == nil)
                .padding(.bottom, 12)
            }
            .navigationTitle("Add Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .alert(isPresented: $showInvalidDateAlert) {
                Alert(title: Text("Invalid Date"), message: Text(invalidDateMessage), dismissButton: .default(Text("OK")))
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
    @Binding var startFromDate: Date
    @Binding var selectedDates: [Date]
    @Binding var showInvalidDateAlert: Bool
    @Binding var invalidDateMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker("Start From", selection: $startFromDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
            Text("Choose history completion dates:")
                .foregroundColor(.secondary)
                .font(.footnote)
            CalendarView(
                isEditing: true,
                pendingAddDates: Binding(get: { Set(selectedDates) }, set: { newDates in
                    // 日期校验逻辑
                    let minDate = Calendar.current.startOfDay(for: startFromDate)
                    let maxDate = Calendar.current.startOfDay(for: Date())
                    let invalidDates = newDates.filter { $0 < minDate || $0 > maxDate }
                    if !invalidDates.isEmpty {
                        invalidDateMessage = "Choose dates from start date to today"
                        showInvalidDateAlert = true
                        return // 不更新 selectedDates
                    }
                    selectedDates = Array(newDates)
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
