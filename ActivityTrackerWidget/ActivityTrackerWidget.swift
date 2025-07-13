//
//  ActivityTrackerWidget.swift
//  ActivityTrackerWidget
//
//  Created by Pei on 2025-07-07.
//

import WidgetKit
import SwiftUI
import Intents
import CoreData

// MARK: - Entry
struct ActivityEntry: TimelineEntry {
    let date: Date
    let activities: [ActivityModel]
}

// MARK: - Activity Model for Widget
struct ActivityModel: Identifiable {
    let id: UUID
    let name: String
    let iconName: String
    let daysSinceCompletion: Int
    let isCompletedToday: Bool
}

// MARK: - Timeline Provider
struct ActivityProvider: TimelineProvider {
    func placeholder(in context: Context) -> ActivityEntry {
        ActivityEntry(date: Date(), activities: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (ActivityEntry) -> ()) {
        let activities = WidgetDataProvider.fetchTopActivities()
        completion(ActivityEntry(date: Date(), activities: activities))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ActivityEntry>) -> ()) {
        let activities = WidgetDataProvider.fetchTopActivities()
        let entry = ActivityEntry(date: Date(), activities: activities)
        // 每小时刷新
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Widget Data Provider (App Group Core Data)
struct WidgetDataProvider {
    static func fetchTopActivities(limit: Int = 5) -> [ActivityModel] {
        print("[Widget] fetchTopActivities called")
        let groupID = "group.com.penny.activitytracker"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            print("[Widget] App Group URL not found")
            return []
        }
        let storeURL = groupURL.appendingPathComponent("ActivityTracker.sqlite")
        let container = NSPersistentContainer(name: "ActivityTracker")
        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { desc, error in
            if let error = error {
                print("[Widget] Core Data load error: \(error)")
            } else {
                print("[Widget] Core Data loaded successfully: \(desc)")
            }
        }
        let context = container.viewContext

        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        request.fetchLimit = limit

        do {
            let activities = try context.fetch(request)
            print("[Widget] Fetched activities count: \(activities.count)")
            return activities.map { activity in
                let completions = (activity.completions as? Set<Completion>) ?? []
                let lastCompletion = completions.sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }.first
                let lastDate = lastCompletion?.completedDate ?? .distantPast
                let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? -1
                let isToday = Calendar.current.isDateInToday(lastDate)
                print("[Widget] Activity: \(activity.name ?? ""), lastDate: \(lastDate), days: \(days), isToday: \(isToday)")
                return ActivityModel(
                    id: activity.id ?? UUID(),
                    name: activity.name ?? "",
                    iconName: activity.iconName ?? "circle",
                    daysSinceCompletion: days,
                    isCompletedToday: isToday
                )
            }
        } catch {
            print("[Widget] Fetch activities error: \(error)")
            return []
        }
    }

    static func markComplete(activityID: UUID) {
        print("[Widget] markComplete called for id: \(activityID)")
        let groupID = "group.com.penny.activitytracker"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            print("[Widget] App Group URL not found in markComplete")
            return
        }
        let storeURL = groupURL.appendingPathComponent("ActivityTracker.sqlite")
        let container = NSPersistentContainer(name: "ActivityTracker")
        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { desc, error in
            if let error = error {
                print("[Widget] Core Data load error in markComplete: \(error)")
            } else {
                print("[Widget] Core Data loaded successfully in markComplete: \(desc)")
            }
        }
        let context = container.viewContext

        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", activityID as CVarArg)
        do {
            if let activity = try context.fetch(request).first {
                let completion = Completion(context: context)
                completion.id = UUID()
                completion.completedDate = Date()
                completion.source = "widget"
                completion.activity = activity
                try context.save()
                print("[Widget] markComplete: Completion saved for activity \(activity.name ?? "")")
            } else {
                print("[Widget] markComplete: Activity not found for id \(activityID)")
            }
        } catch {
            print("[Widget] markComplete fetch/save error: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Widget View
struct ActivityTrackerWidgetEntryView: View {
    var entry: ActivityProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        GeometryReader { geo in
            if entry.activities.isEmpty {
                Text("No Activities")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 12) {
                    ForEach(entry.activities.prefix(3)) { activity in
                        VStack(spacing: 8) {
                            Image(systemName: activity.iconName)
                                .font(.system(size: 28))
                            Text(activity.name)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(activity.daysSinceCompletion >= 0 ? "\(activity.daysSinceCompletion) days ago" : "Never")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(activity.isCompletedToday ? .green : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 8)
            }
        }
    }
}

// MARK: - Widget 配置
struct ActivityTrackerWidget: Widget {
    let kind: String = "ActivityTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActivityProvider()) { entry in
            ActivityTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Activity Tracker")
        .description("Quickly complete and view your top activities.")
        .supportedFamilies([.systemMedium])
    }
}

struct ActivityTrackerWidget_Previews: PreviewProvider {
    static var previews: some View {
        let mockActivities = [
            ActivityModel(id: UUID(), name: "Meditation", iconName: "leaf.fill", daysSinceCompletion: 2, isCompletedToday: false),
            ActivityModel(id: UUID(), name: "Exercise", iconName: "figure.run", daysSinceCompletion: 0, isCompletedToday: true),
            ActivityModel(id: UUID(), name: "Reading", iconName: "book.fill", daysSinceCompletion: 5, isCompletedToday: false)
        ]
        ActivityTrackerWidgetEntryView(entry: ActivityEntry(date: Date(), activities: mockActivities))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
