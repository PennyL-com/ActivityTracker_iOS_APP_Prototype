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
        
        if inMemory {
            // 内存存储模式：将存储 URL 设置为 /dev/null
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // 使用应用沙盒的默认存储位置
            print("Using default app sandbox storage")
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
