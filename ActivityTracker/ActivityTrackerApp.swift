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
    ActivityTrackerApp()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 