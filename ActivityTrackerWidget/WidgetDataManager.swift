import Foundation
import CoreData
import WidgetKit

/// 小组件数据管理器 - 负责处理小组件与主应用之间的数据同步
class WidgetDataManager {
    /// 单例实例
    static let shared = WidgetDataManager()
    
    /// App Group ID
    private let groupID = "group.com.penny.activitytracker"
    
    /// Core Data 容器
    private var container: NSPersistentContainer?
    
    /// 私有初始化方法
    private init() {
        setupCoreDataContainer()
        initializePageInfo()
        setupDataChangeObserver()
    }
    
    // MARK: - Core Data Setup
    
    /// 初始化页码信息
    private func initializePageInfo() {
        let defaults = UserDefaults(suiteName: groupID)
        if defaults?.object(forKey: "widget_current_page") == nil {
            defaults?.set(1, forKey: "widget_current_page")
        }
        if defaults?.object(forKey: "widget_total_pages") == nil {
            defaults?.set(1, forKey: "widget_total_pages")
        }
    }
    
    /// 设置 Core Data 容器
    private func setupCoreDataContainer() {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            print("[WidgetDataManager] App Group URL not found")
            return
        }
        
        let storeURL = groupURL.appendingPathComponent("ActivityTracker.sqlite")
        container = NSPersistentContainer(name: "ActivityTracker")
        
        guard let container = container else {
            print("[WidgetDataManager] Failed to create container")
            return
        }
        
        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { desc, error in
            if let error = error {
                print("[WidgetDataManager] Core Data load error: \(error)")
            } else {
                print("[WidgetDataManager] Core Data loaded successfully: \(desc)")
            }
        }
    }
    
    // MARK: - Data Fetching
    
    /// 获取分页活动数据
    /// - Parameter pageSize: 每页显示的活动数量
    /// - Returns: 当前页的活动模型数组
    func fetchPagedActivities(pageSize: Int = 6) -> [ActivityModel] {
        guard let container = container else {
            print("[WidgetDataManager] Container not available")
            return []
        }
        
        let context = container.viewContext
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        
        // 按照dashboard的sortOrder排序，与app内保持一致
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: false)]
        
        do {
            let allActivities = try context.fetch(request)
            print("[WidgetDataManager] Total activities: \(allActivities.count)")
            
            // 如果没有活动数据，直接返回空数组
            if allActivities.isEmpty {
                let defaults = UserDefaults(suiteName: groupID)
                defaults?.set(1, forKey: "widget_total_pages")
                defaults?.set(1, forKey: "widget_current_page")
                return []
            }
            
            // 计算总页数并保存到UserDefaults
            let totalPages = max(1, (allActivities.count + pageSize - 1) / pageSize)
            let defaults = UserDefaults(suiteName: groupID)
            defaults?.set(totalPages, forKey: "widget_total_pages")
            
            // 获取当前页
            var currentPage = defaults?.integer(forKey: "widget_current_page") ?? 1
            
            // 确保当前页不超过总页数
            if currentPage > totalPages {
                currentPage = totalPages
                defaults?.set(currentPage, forKey: "widget_current_page")
            }
            
            let startIndex = (currentPage - 1) * pageSize
            let endIndex = min(startIndex + pageSize, allActivities.count)
            
            // 确保索引有效
            guard startIndex < allActivities.count else {
                print("[WidgetDataManager] Invalid page index: \(currentPage)")
                return []
            }
            
            let pageActivities = Array(allActivities[startIndex..<endIndex])
            print("[WidgetDataManager] Page \(currentPage)/\(totalPages): \(pageActivities.count) activities")
            
            return pageActivities.map { activity in
                convertToActivityModel(activity)
            }
        } catch {
            print("[WidgetDataManager] Fetch activities error: \(error)")
            return []
        }
    }
    
    /// 获取前N个活动（按sortOrder降序排列）- 保持向后兼容
    /// - Parameter limit: 获取的活动数量，默认为6
    /// - Returns: 活动模型数组
    func fetchTopActivities(limit: Int = 6) -> [ActivityModel] {
        // 根据小组件尺寸决定每页显示数量
        let pageSize = limit
        return fetchPagedActivities(pageSize: pageSize)
    }
    
    /// 根据Widget尺寸获取活动数据
    /// - Parameter isLarge: 是否为大尺寸Widget
    /// - Returns: 活动模型数组
    func fetchActivitiesForWidgetSize(isLarge: Bool) -> [ActivityModel] {
        // 检查日期变化
        checkAndUpdateWidgetForDateChange()
        
        guard let container = container else {
            print("[WidgetDataManager] Container not available")
            return []
        }
        
        let context = container.viewContext
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        
        // 按照dashboard的sortOrder排序，与app内保持一致
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: false)]
        
        // 大尺寸：获取前6条数据，不分页
        if isLarge {
            request.fetchLimit = 6
            do {
                let activities = try context.fetch(request)
                print("[WidgetDataManager] Large widget: fetched \(activities.count) activities")
                return activities.map { convertToActivityModel($0) }
            } catch {
                print("[WidgetDataManager] Fetch activities error: \(error)")
                return []
            }
        } else {
            // 中尺寸：获取前6条数据，然后分页处理
            request.fetchLimit = 6
            do {
                let allActivities = try context.fetch(request)
                print("[WidgetDataManager] Medium widget: total \(allActivities.count) activities")
                
                if allActivities.isEmpty {
                    let defaults = UserDefaults(suiteName: groupID)
                    defaults?.set(1, forKey: "widget_total_pages")
                    defaults?.set(1, forKey: "widget_current_page")
                    return []
                }
                
                // 中尺寸固定为2页，每页3条
                let totalPages = 2
                let pageSize = 3
                let defaults = UserDefaults(suiteName: groupID)
                defaults?.set(totalPages, forKey: "widget_total_pages")
                
                // 获取当前页
                var currentPage = defaults?.integer(forKey: "widget_current_page") ?? 1
                if currentPage > totalPages {
                    currentPage = totalPages
                    defaults?.set(currentPage, forKey: "widget_current_page")
                }
                
                let startIndex = (currentPage - 1) * pageSize
                let endIndex = min(startIndex + pageSize, allActivities.count)
                
                guard startIndex < allActivities.count else {
                    print("[WidgetDataManager] Invalid page index: \(currentPage)")
                    return []
                }
                
                let pageActivities = Array(allActivities[startIndex..<endIndex])
                print("[WidgetDataManager] Medium widget: Page \(currentPage)/\(totalPages): \(pageActivities.count) activities")
                
                return pageActivities.map { convertToActivityModel($0) }
            } catch {
                print("[WidgetDataManager] Fetch activities error: \(error)")
                return []
            }
        }
    }
    
    /// 将 Core Data Activity 转换为小组件 ActivityModel
    /// - Parameter activity: Core Data Activity 对象
    /// - Returns: 小组件 ActivityModel
    private func convertToActivityModel(_ activity: Activity) -> ActivityModel {
        let completions = (activity.completions as? Set<Completion>) ?? []
        
        // 计算最后完成日期和天数
        let lastCompletion = completions.sorted { 
            ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) 
        }.first
        let lastDate = lastCompletion?.completedDate ?? .distantPast
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? -1
        
        // 检查今天是否已完成
        let isToday = completions.contains { completion in
            if let date = completion.completedDate {
                return Calendar.current.isDateInToday(date)
            }
            return false
        }
        
        print("[WidgetDataManager] Activity: \(activity.name ?? ""), lastDate: \(lastDate), days: \(days), isToday: \(isToday)")
        
        return ActivityModel(
            id: activity.id ?? UUID(),
            name: activity.name ?? "",
            iconName: activity.iconName ?? "circle",
            daysSinceCompletion: days,
            isCompletedToday: isToday
        )
    }
    
    // MARK: - Data Modification
    
    /// 为指定活动添加完成记录（打钩功能）
    /// - Parameter activityID: 活动ID
    /// - Returns: 是否成功添加完成记录
    func markActivityComplete(activityID: UUID) -> Bool {
        guard let container = container else {
            print("[WidgetDataManager] Container not available for markComplete")
            return false
        }
        
        let context = container.viewContext
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", activityID as CVarArg)
        
        do {
            if let activity = try context.fetch(request).first {
                // 检查今天是否已经完成
                let completions = (activity.completions as? Set<Completion>) ?? []
                let isCompletedToday = completions.contains { completion in
                    if let date = completion.completedDate {
                        return Calendar.current.isDateInToday(date)
                    }
                    return false
                }
                
                if !isCompletedToday {
                    let completion = Completion(context: context)
                    completion.id = UUID()
                    completion.completedDate = Date()
                    completion.source = "widget"
                    completion.activity = activity
                    
                    try context.save()
                    print("[WidgetDataManager] Successfully marked activity complete: \(activity.name ?? "")")
                    
                    // 强制刷新小组件时间线，确保状态立即更新
                    forceRefreshWidget()
                    return true
                } else {
                    print("[WidgetDataManager] Activity already completed today: \(activity.name ?? "")")
                    return false
                }
            } else {
                print("[WidgetDataManager] Activity not found for id: \(activityID)")
                return false
            }
        } catch {
            print("[WidgetDataManager] Error marking activity complete: \(error)")
            return false
        }
    }
    
    // MARK: - Widget Timeline Management
    
    /// 刷新小组件时间线
    func refreshWidgetTimeline() {
        WidgetCenter.shared.reloadTimelines(ofKind: "ActivityTrackerWidget")
        print("[WidgetDataManager] Widget timeline refreshed")
    }
    
    /// 强制刷新小组件时间线（用于重要数据变化）
    func forceRefreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()
        print("[WidgetDataManager] Widget timeline force refreshed")
    }
    
    /// 监听数据变化并自动刷新小组件
    func setupDataChangeObserver() {
        guard let container = container else { return }
        
        // 监听 Core Data 变化
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: container.viewContext,
            queue: .main
        ) { _ in
            self.refreshWidgetTimeline()
        }
        
        // 监听应用状态变化，确保日期变化时能及时更新
        // 注意：在小组件扩展中，UIApplication不可用，所以这里只监听Core Data变化
        // 日期变化检查将在每次获取数据时进行
    }
    
    /// 检查日期变化并更新小组件
    private func checkAndUpdateWidgetForDateChange() {
        let defaults = UserDefaults(suiteName: groupID)
        let lastUpdateDate = defaults?.object(forKey: "widget_last_update_date") as? Date ?? Date.distantPast
        
        if !Calendar.current.isDateInToday(lastUpdateDate) {
            // 日期已变化，更新小组件
            defaults?.set(Date(), forKey: "widget_last_update_date")
            forceRefreshWidget()
            print("[WidgetDataManager] Date changed, widget updated")
        }
    }
    
    // MARK: - Data Validation
    
    /// 验证数据完整性
    /// - Returns: 验证结果
    func validateData() -> Bool {
        guard let container = container else {
            print("[WidgetDataManager] Container not available for validation")
            return false
        }
        
        let context = container.viewContext
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            print("[WidgetDataManager] Data validation: found \(count) activities")
            return true
        } catch {
            print("[WidgetDataManager] Data validation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Error Handling
    
    /// 处理数据错误
    /// - Parameter error: 错误信息
    private func handleError(_ error: Error) {
        print("[WidgetDataManager] Error: \(error)")
        // 可以在这里添加错误上报逻辑
    }
}

// MARK: - Activity Model for Widget
struct ActivityModel: Identifiable {
    let id: UUID
    let name: String
    let iconName: String
    let daysSinceCompletion: Int
    let isCompletedToday: Bool
} 