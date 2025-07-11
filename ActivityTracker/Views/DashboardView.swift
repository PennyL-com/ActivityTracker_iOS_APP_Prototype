import SwiftUI

struct DashboardView: View {
    @State private var showAdd = false
    @State private var showEdit: Activity?
    let manager = ActivityDataManager.shared
    @State private var activities: [Activity] = []

    private func reload() {
        activities = manager.fetchActivities()
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(activities, id: \ .id) { activity in
                    NavigationLink(destination: ActivityDetailView(activity: activity)) {
                        HStack {
                            Image(systemName: activity.iconName ?? "circle")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text(activity.name ?? "")
                                    .font(.headline)
                                Text("Last: \(daysSinceLastCompletion(activity: activity)) days ago")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                _ = manager.addCompletion(to: activity, source: "app")
                                reload()
                            } label: {
                                Image(systemName: "checkmark.circle")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            manager.deleteActivity(activity)
                            reload()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            showEdit = activity
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                }
            }
            .navigationTitle("Activities")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add Activity", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: reload) {
                AddActivityView(onSave: reload)
            }
            .sheet(item: $showEdit, onDismiss: reload) { activity in
                EditActivityView(activity: activity, onSave: reload)
            }
            .onAppear(perform: reload)
        }
    }

    func daysSinceLastCompletion(activity: Activity) -> Int {
        let completions = manager.fetchCompletions(for: activity)
        guard let last = completions.first?.completedDate else { return -1 }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? -1
    }
} 