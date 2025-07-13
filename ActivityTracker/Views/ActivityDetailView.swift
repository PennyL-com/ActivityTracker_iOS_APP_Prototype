import SwiftUI

struct ActivityDetailView: View {
    var activity: Activity
    let manager = ActivityDataManager.shared
    @State private var completions: [Completion] = []

    private func reload() {
        completions = manager.fetchCompletions(for: activity)
    }

    var body: some View {
        List {
            Section(header: Text("Records")) {
                HStack {
                    Text("Last Done")
                    Spacer()
                    Text("\(daysSinceLastCompletion()) days ago")
                        .foregroundColor(.blue)
                }
                if completions.isEmpty {
                    Text("No completion history yet.")
                        .foregroundColor(.secondary)
                } else {
                    let uniqueCompletions = Dictionary(grouping: completions) { completion in
                        completion.completedDate.map { Calendar.current.startOfDay(for: $0) } ?? Date.distantPast
                    }.compactMap { $0.value.first }.sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
                    ForEach(uniqueCompletions, id: \.id) { completion in
                        HStack {
                            Image(systemName: "checkmark.seal")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(completion.completedDate ?? Date(), style: .date)
                                if let source = completion.source {
                                    Text(source)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            Section(header: Text("Activity Info")) {
                HStack {
                    Text("Category")
                    Spacer()
                    Text(activity.category ?? "-")
                        .foregroundColor(.blue)
                }
                if let notes = activity.optionalDetails, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(activity.name ?? "")
        .onAppear(perform: reload)
    }

    func daysSinceLastCompletion() -> Int {
        let completions = manager.fetchCompletions(for: activity)
        guard let last = completions.first?.completedDate else { return -1 }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? -1
    }

}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let mockActivity = Activity(context: context)
    mockActivity.id = UUID()
    mockActivity.name = "Sample Activity"
    mockActivity.category = "Health"
    mockActivity.optionalDetails = "This is a sample activity for preview"
    mockActivity.createdDate = Date()
    
    // 添加一些模拟的完成记录
    let completion1 = Completion(context: context)
    completion1.id = UUID()
    completion1.completedDate = Date()
    completion1.source = "app"
    completion1.activity = mockActivity
    
    let completion2 = Completion(context: context)
    completion2.id = UUID()
    completion2.completedDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    completion2.source = "widget"
    completion2.activity = mockActivity
    
    return ActivityDetailView(activity: mockActivity)
        .environment(\.managedObjectContext, context)
    
} 