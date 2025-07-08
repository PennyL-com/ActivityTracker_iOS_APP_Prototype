//
//  ActivityTrackerApp.swift
//  ActivityTracker
//
//  Created by Pei on 2025-07-07.
//

import SwiftUI

@main
struct ActivityTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
