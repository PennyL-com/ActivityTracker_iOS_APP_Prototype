import SwiftUI

struct DashboardView: View {
    @State private var showAdd = false
    @State private var showEdit: Activity?
    @State private var selectedActivity: Activity? = nil
    let manager = ActivityDataManager.shared
    @State private var activities: [Activity] = []

    private func reload() {
        activities = manager.fetchActivities()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Okie dokie, let's start it!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(activities, id: \ .id) { activity in
                            let completions = (activity.completions as? Set<Completion>) ?? []
                            let isCompletedToday = completions.contains { completion in
                                if let date = completion.completedDate {
                                    return Calendar.current.isDateInToday(date)
                                }
                                return false
                            }
                            ActivityCardView(
                                activity: activity,
                                isCompletedToday: isCompletedToday,
                                onComplete: {
                                    _ = manager.addCompletion(to: activity, source: "app")
                                    reload()
                                },
                                onEdit: {
                                    showEdit = activity
                                },
                                onDelete: {
                                    manager.deleteActivity(activity)
                                    reload()
                                },
                                onTapCard: {
                                    selectedActivity = activity
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    manager.deleteActivity(activity)
                                    reload()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                Spacer()
                Button(action: { showAdd = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text(LocalizedStringKey("Add Activity"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .padding([.horizontal, .bottom])
            }
            .sheet(isPresented: $showAdd, onDismiss: reload) {
                AddActivityView(onSave: reload)
            }
            .sheet(item: $showEdit, onDismiss: reload) { activity in
                EditActivityView(activity: activity, onSave: reload)
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
            .onAppear(perform: reload)
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }

    func daysSinceLastCompletion(activity: Activity) -> Int {
        let completions = manager.fetchCompletions(for: activity)
        guard let last = completions.first?.completedDate else { return -1 }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? -1
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 