import SwiftUI
import CoreData

struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var category = "Hobby"
    @State private var optionalDetails = ""
    @State private var priorityRank: Int16 = 0
    @State private var iconName = "star"
    @State private var isCompleted = false // 添加completed状态
    let categories = ["Hobby", "Health", "Pet", "Home", "Others", "Education"].sorted()

    var onSave: () -> Void
    //TODO：这个view少一个可选icon功能
    

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
                        let activity = ActivityDataManager.shared.createActivity(
                            name: name,
                            category: category,
                            iconName: iconName,
                            optionalDetails: optionalDetails.isEmpty ? nil : optionalDetails,
                            createdDate: Date(),
                            isCompleted: isCompleted
                        )
                        
                        // 如果用户选择了completed，立即添加完成记录
                        if isCompleted {
                            _ = ActivityDataManager.shared.addCompletion(to: activity, source: "app")//TODO：source 需要传入补全逻辑
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