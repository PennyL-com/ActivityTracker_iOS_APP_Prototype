import Foundation
import CoreData

/// 活动数据管理器 - 负责处理所有与活动相关的 Core Data 操作
class ActivityDataManager {
    /// 单例实例，确保整个应用使用同一个数据管理器
    static let shared = ActivityDataManager()
    /// Core Data 上下文，用于执行数据操作
    let context: NSManagedObjectContext

    /// 私有初始化方法，使用默认的 Core Data 上下文
    private init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Activity CRUD

    /// 创建新的活动记录
    /// - Parameters:
    ///   - name: 活动名称
    ///   - category: 活动类别
    ///   - iconName: 图标名称，可选
    ///   - optionalDetails: 可选的详细描述
    ///   - createdDate: 创建日期，默认为当前时间
    /// - Returns: 新创建的活动对象
    func createActivity(
        name: String,
        category: String,
        iconName: String? = nil,
        optionalDetails: String? = nil,
        createdDate: Date = Date()
    ) -> Activity {
        // 在 Core Data 上下文中创建新的 Activity 实体
        let activity = Activity(context: context)
        activity.id = UUID() // 生成唯一标识符
        activity.name = name
        activity.category = category
        activity.iconName = iconName
        activity.optionalDetails = optionalDetails
        activity.createdDate = createdDate
        save() // 保存到 Core Data
        return activity
    }

    /// 获取所有活动记录，按创建日期降序排列
    /// - Returns: 活动数组，如果出错则返回空数组
    func fetchActivities() -> [Activity] {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        // 按创建日期降序排列，最新的活动在前
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch Activities Error: \(error)")
            return [] // 出错时返回空数组
        }
    }

    /// 删除指定的活动记录
    /// - Parameter activity: 要删除的活动对象
    func deleteActivity(_ activity: Activity) {
        context.delete(activity) // 从上下文中删除活动
        save() // 保存更改
    }

    // MARK: - Completion CRUD

    /// 为指定活动添加完成记录
    /// - Parameters:
    ///   - activity: 要添加完成记录的活动
    ///   - completedDate: 完成日期，默认为当前时间
    ///   - source: 完成来源（如：手动添加、小部件等）
    /// - Returns: 新创建的完成记录对象
    func addCompletion(
        to activity: Activity,
        completedDate: Date = Date(),
        source: String
    ) -> Completion {
        // 在 Core Data 上下文中创建新的 Completion 实体
        let completion = Completion(context: context)
        completion.id = UUID() // 生成唯一标识符
        completion.completedDate = completedDate
        completion.source = source
        completion.activity = activity // 建立与活动的关联关系
        save() // 保存到 Core Data
        return completion
    }

    /// 获取指定活动的所有完成记录
    /// - Parameter activity: 要查询完成记录的活动
    /// - Returns: 完成记录数组，按完成日期降序排列
    func fetchCompletions(for activity: Activity) -> [Completion] {
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        // 只查询属于指定活动的完成记录
        request.predicate = NSPredicate(format: "activity == %@", activity)
        // 按完成日期降序排列，最新的完成记录在前
        request.sortDescriptors = [NSSortDescriptor(key: "completedDate", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch Completions Error: \(error)")
            return [] // 出错时返回空数组
        }
    }

    /// 删除指定的完成记录
    /// - Parameter completion: 要删除的完成记录对象
    func deleteCompletion(_ completion: Completion) {
        context.delete(completion) // 从上下文中删除完成记录
        save() // 保存更改
    }

    // MARK: - Save
    /// 保存 Core Data 上下文中的所有更改
    /// 只有在上下文有更改时才会执行保存操作
    func save() {
        if context.hasChanges { // 检查是否有未保存的更改
            do {
                try context.save() // 尝试保存到持久化存储
            } catch {
                print("Save Error: \(error)") // 打印保存错误信息
            }
        }
    }
} 