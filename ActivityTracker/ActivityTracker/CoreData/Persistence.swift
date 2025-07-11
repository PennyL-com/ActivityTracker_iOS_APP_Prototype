import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // 这里可以自定义预览数据
        for _ in 0..<10 {
            // 示例：创建预览 Activity
            let activity = Activity(context: viewContext)
            activity.id = UUID()
            activity.name = "Preview Activity"
            activity.category = "Preview"
            activity.createdDate = Date()
            activity.priorityRank = 0
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ActivityTracker")
        let groupID = "group.com.penny.activitytracker"
        let storeName = "ActivityTracker.sqlite"
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            let storeURL = groupURL.appendingPathComponent(storeName)
            let description = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [description]
        } else {
            fatalError("无法获取 App Group 目录，请检查 App Group 配置")
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        print("Core Data store URL: \(container.persistentStoreDescriptions.first?.url?.absoluteString ?? "nil")")
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
} 