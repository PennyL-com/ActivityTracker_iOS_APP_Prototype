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
        
        // 创建示例数据用于 SwiftUI 预览
        for _ in 0..<10 {
            // 创建预览用的活动数据
            let activity = Activity(context: viewContext)
            activity.id = UUID()
            activity.name = "Preview Activity"
            activity.category = "Preview"
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
        
        // App Group 标识符，用于在应用和小组件之间共享数据
        let groupID = "group.com.penny.activitytracker"
        let storeName = "ActivityTracker.sqlite"
        
        if inMemory {
            // 内存存储模式：将存储 URL 设置为 /dev/null
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            // 使用 App Group 共享目录存储数据库文件
            let storeURL = groupURL.appendingPathComponent(storeName)
            let description = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [description]
        } else {
            // 如果无法获取 App Group 目录，抛出致命错误
            fatalError("无法获取 App Group 目录，请检查 App Group 配置")
        }

        // 加载持久化存储
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // 如果加载失败，抛出致命错误
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // 打印存储 URL 用于调试
        print("Core Data store URL: \(container.persistentStoreDescriptions.first?.url?.absoluteString ?? "nil")")
        
        // 启用自动合并来自父上下文的更改
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
} 
