import SwiftUI

struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var category = "Hobby"
    @State private var optionalDetails = ""
    @State private var priorityRank: Int16 = 0
    @State private var iconName = "star"
    let categories = ["Hobby", "Health", "Career", "Education", "Custom"]
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
                    TextField("Details", text: $optionalDetails)
                }
                Section(header: Text("Priority & Icon")) {
                    Stepper("Priority: \(priorityRank)", value: $priorityRank, in: 0...5)
                    TextField("SF Symbol", text: $iconName)
                        .autocapitalization(.none)
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
                            optionalDetails: optionalDetails.isEmpty ? nil : optionalDetails,
                            priorityRank: priorityRank,
                            iconName: iconName.isEmpty ? nil : iconName
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