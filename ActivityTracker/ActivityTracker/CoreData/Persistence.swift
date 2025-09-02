import CoreData

/// Core Data 持久化控制器
/// 负责管理 Core Data 堆栈和数据库操作
struct PersistenceController {
    /// 单例实例，确保整个应用使用同一个 Core Data 堆栈
    static let shared = PersistenceController()

    /// 预览环境使用的持久化控制器
    /// 使用内存存储，不会影响实际数据库
    @MainActor
    static let preview: PersistenceController = {
        // 创建内存存储的持久化控制器
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 创建默认分类
        let lifeCategory = Category(context: viewContext)
        lifeCategory.categoryId = UUID()
        lifeCategory.name = "Life"
        lifeCategory.defaultKey = "life"
        
        let studyCategory = Category(context: viewContext)
        studyCategory.categoryId = UUID()
        studyCategory.name = "Study"
        studyCategory.defaultKey = "study"
        
        let workCategory = Category(context: viewContext)
        workCategory.categoryId = UUID()
        workCategory.name = "Work"
        workCategory.defaultKey = "work"
        
        // 创建示例数据用于 SwiftUI 预览
        for _ in 0..<10 {
            let category = Category(context: viewContext)
            category.categoryId = UUID()
            category.name = "Preview Category"
            let activity = Activity(context: viewContext)
            activity.id = UUID()
            activity.name = "Preview Activity"
            activity.belongToCategory = category
            activity.createdDate = Date()
        }
        
        // 保存预览数据到内存存储
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    /// Core Data 容器，管理数据模型和存储
    let container: NSPersistentContainer

    /// 初始化持久化控制器
    /// - Parameter inMemory: 是否使用内存存储（用于测试和预览）
    init(inMemory: Bool = false) {
        // 创建 Core Data 容器，指定数据模型名称
        container = NSPersistentContainer(name: "ActivityTracker")
        
        if inMemory {
            // 内存存储模式：将存储 URL 设置为 /dev/null
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // 使用 App Group 共享存储位置
            let groupID = "group.com.penny.activitytracker"
            if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
                let storeURL = groupURL.appendingPathComponent("ActivityTracker.sqlite")
                container.persistentStoreDescriptions.first!.url = storeURL
            } else {
                print("App Group not available, using default storage")
            }
        }
        
        // 配置持久化存储描述符，确保配置一致
        for storeDescription in container.persistentStoreDescriptions {
            // 启用历史跟踪以匹配之前的配置
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            // 设置轻量级迁移选项
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        // 加载持久化存储
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // 如果加载失败，抛出致命错误
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // 启用自动合并来自父上下文的更改
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
} 
