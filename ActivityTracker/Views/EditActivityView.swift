import SwiftUI

struct EditActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    let manager = ActivityDataManager.shared
    @State private var name: String
    @State private var category: String
    @State private var optionalDetails: String
    let categories = ["Hobby", "Health", "Pet", "Home", "Others", "Education"].sorted()
    var activity: Activity
    var onSave: () -> Void

    init(activity: Activity, onSave: @escaping () -> Void) {
        self.activity = activity
        self.onSave = onSave
        _name = State(initialValue: activity.name ?? "")
        _category = State(initialValue: activity.category ?? "Hobby")
        _optionalDetails = State(initialValue: activity.optionalDetails ?? "")
    }

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
            .navigationTitle("Edit Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        activity.name = name
                        activity.category = category
                        activity.optionalDetails = optionalDetails
                        manager.save()
                        onSave()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
} 