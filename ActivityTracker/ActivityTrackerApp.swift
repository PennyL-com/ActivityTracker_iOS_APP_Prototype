import SwiftUI
import CoreData

@main
struct ActivityTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 