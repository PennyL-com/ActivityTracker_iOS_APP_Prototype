import Foundation
import CoreData

class ActivityDataManager {
    static let shared = ActivityDataManager()
    let context: NSManagedObjectContext

    private init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Activity CRUD

    func createActivity(
        name: String,
        category: String,
        optionalDetails: String? = nil,
        createdDate: Date = Date()
    ) -> Activity {
        let activity = Activity(context: context)
        activity.id = UUID()
        activity.name = name
        activity.category = category
        activity.optionalDetails = optionalDetails
        activity.createdDate = createdDate
        save()
        return activity
    }

    func fetchActivities() -> [Activity] {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch Activities Error: \(error)")
            return []
        }
    }

    func deleteActivity(_ activity: Activity) {
        context.delete(activity)
        save()
    }

    // MARK: - Completion CRUD

    func addCompletion(
        to activity: Activity,
        completedDate: Date = Date(),
        source: String
    ) -> Completion {
        let completion = Completion(context: context)
        completion.id = UUID()
        completion.completedDate = completedDate
        completion.source = source
        completion.activity = activity
        save()
        return completion
    }

    func fetchCompletions(for activity: Activity) -> [Completion] {
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        request.predicate = NSPredicate(format: "activity == %@", activity)
        request.sortDescriptors = [NSSortDescriptor(key: "completedDate", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch Completions Error: \(error)")
            return []
        }
    }

    func deleteCompletion(_ completion: Completion) {
        context.delete(completion)
        save()
    }

    // MARK: - Save

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save Error: \(error)")
            }
        }
    }
} 