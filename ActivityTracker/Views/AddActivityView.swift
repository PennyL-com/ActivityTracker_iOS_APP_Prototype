import SwiftUI

struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var category = "Hobby"
    @State private var optionalDetails = ""
    @State private var priorityRank: Int16 = 0
    @State private var iconName = "star"
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
                        _ = ActivityDataManager.shared.createActivity(
                            name: name,
                            category: category,
                            optionalDetails: optionalDetails.isEmpty ? nil : optionalDetails
                        )
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