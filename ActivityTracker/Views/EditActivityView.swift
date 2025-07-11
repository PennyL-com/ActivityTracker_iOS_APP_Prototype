import SwiftUI

struct EditActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    let manager = ActivityDataManager.shared
    @State private var name: String
    @State private var category: String
    @State private var optionalDetails: String
    @State private var priorityRank: Int16
    @State private var iconName: String
    let categories = ["Hobby", "Health", "Career", "Education", "Custom"]
    var activity: Activity
    var onSave: () -> Void

    init(activity: Activity, onSave: @escaping () -> Void) {
        self.activity = activity
        self.onSave = onSave
        _name = State(initialValue: activity.name ?? "")
        _category = State(initialValue: activity.category ?? "Hobby")
        _optionalDetails = State(initialValue: activity.optionalDetails ?? "")
        _priorityRank = State(initialValue: activity.priorityRank)
        _iconName = State(initialValue: activity.iconName ?? "star")
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
                Section(header: Text("Priority & Icon")) {
                    Stepper("Priority: \(priorityRank)", value: $priorityRank, in: 0...5)
                    TextField("SF Symbol", text: $iconName)
                        .autocapitalization(.none)
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
                        activity.priorityRank = priorityRank
                        activity.iconName = iconName
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