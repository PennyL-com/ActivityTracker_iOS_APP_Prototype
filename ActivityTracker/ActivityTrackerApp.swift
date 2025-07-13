import SwiftUI

@main
struct ActivityTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 