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
            Section(header: Text("Completion History")) {
                ForEach(completions, id: \.id) { completion in
                    HStack {
                        Image(systemName: "checkmark.seal")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text(completion.completedDate ?? Date(), style: .date)
                            Text(completion.source ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(activity.name ?? "")
        .onAppear(perform: reload)
    }
} 