import SwiftUI
import CoreData

struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var category = "Hobby"
    @State private var optionalDetails = ""
    @State private var isCompleted = false // 添加completed状态
    @State private var selectedEmoji: String = ""
    @State private var showEmojiPicker = false
    // 新增：日期选择相关状态
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    

    let categories = ["Hobby", "Health", "Pet", "Home", "Others", "Education"].sorted()
    var onSave: () -> Void
    

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat)
                        }
                    }
                    // Completed状态选择器
                    HStack {
                        Text("Completed Today")
                        Spacer()
                        Toggle("", isOn: $isCompleted)
                            .onChange(of: isCompleted) { value in
                                if !value {
                                    selectedDate = Date()
                                }
                            }
                    }
                    // 新增：直接在表单内显示日期选择器
                    if isCompleted {
                        DatePicker("Choose your completed date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
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
                    
                    TextField("Details", text: $optionalDetails)
                }
            }
            .navigationTitle("Add Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("Creating activity: \(name)")
                        print("AddActivityView: isCompleted = \(isCompleted)")
                        // 判断用户选择的日期是否为今天
                        let isToday = Calendar.current.isDateInToday(selectedDate)
                        let activity = ActivityDataManager.shared.createActivity(
                            name: name,
                            category: category,
                            iconName: selectedEmoji,
                            optionalDetails: optionalDetails.isEmpty ? nil : optionalDetails,
                            createdDate: Date(),
                            isCompleted: isToday // 只有今天才设置为已完成，卡片才会打钩
                        )
                        print("Activity created with ID: \(activity.id?.uuidString ?? "nil")")
                        print("Activity created with isCompleted: \(activity.isCompleted)")
                        // 如果用户选择了completed，立即添加完成记录，日期为用户选定日期（未选则为今天）
                        if isCompleted {
                            ActivityDataManager.shared.addCompletion(to: activity, completedDate: selectedDate, source: "app")
                            print("Completion record added")
                        }
                        onSave()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddActivityView(onSave: {})
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
