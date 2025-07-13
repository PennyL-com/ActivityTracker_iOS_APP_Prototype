import SwiftUI

struct ActivityCardView: View {
    let activity: Activity
    let isCompletedToday: Bool // TODO
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTapCard: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 48, height: 48)
                Image(systemName: activity.iconName ?? "circle")
                    .font(.system(size: 28))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name ?? "")
                    .font(.headline)
                Text("Last done: \(daysSinceLastCompletion()) days ago")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                if !isCompletedToday {
                    onComplete()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isCompletedToday ? Color.accentColor : Color(.systemGray5))
                        .frame(width: 32, height: 32)
                    Image(systemName: isCompletedToday ? "checkmark" : "checkmark.circle")
                        .foregroundColor(isCompletedToday ? .white : .accentColor)
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isCompletedToday)
            .contentShape(Circle())
            .simultaneousGesture(
                TapGesture().onEnded { }
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color(.black).opacity(0.04), radius: 6, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapCard()
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func daysSinceLastCompletion() -> Int {
        let completions = (activity.completions as? Set<Completion>)?.sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
        guard let last = completions?.first?.completedDate else { return -1 }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? -1
    }

}


#Preview {
    let context = PersistenceController.preview.container.viewContext
    let mockActivity = Activity(context: context)
    mockActivity.id = UUID()
    mockActivity.name = "Meditation"
    mockActivity.iconName = "leaf.fill"
    mockActivity.category = "Health"
    mockActivity.createdDate = Date()
    
    // 添加模拟的完成记录
    let mockCompletion = Completion(context: context)
    mockCompletion.id = UUID()
    mockCompletion.completedDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
    mockCompletion.source = "app"
    mockCompletion.activity = mockActivity
    
    return ActivityCardView(
        activity: mockActivity,
        isCompletedToday: false,
        onComplete: { print("✅") },
        onEdit: { print("✏️") },
        onDelete: { print("🗑️") },
        onTapCard: { print("👆") }
    )
    .environment(\.managedObjectContext, context)
    .padding()
}

