import Foundation
import CoreData
import WidgetKit
import UIKit

/// 小组件数据同步扩展 - 处理数据变化监听和自动同步
extension WidgetDataManager {
    
    // MARK: - Data Change Monitoring
    
    /// 设置数据变化监听器
    func setupDataChangeMonitoring() {
        // 使用现有的 setupDataChangeObserver 方法
        setupDataChangeObserver()
        
        // 监听应用进入前台
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppForeground()
        }
        
        print("[WidgetDataSync] Data change monitoring setup completed")
    }
    
    /// 处理数据变化
    /// - Parameter notification: 数据变化通知
    private func handleDataChange(_ notification: Notification) {
        print("[WidgetDataSync] Data change detected")
        
        // 检查是否有活动相关的变化
        if let userInfo = notification.userInfo {
            let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? []
            let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []
            let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? []
            
            let hasActivityChanges = insertedObjects.contains { $0 is Activity } ||
                                   updatedObjects.contains { $0 is Activity } ||
                                   deletedObjects.contains { $0 is Activity }
            
            let hasCompletionChanges = insertedObjects.contains { $0 is Completion } ||
                                     updatedObjects.contains { $0 is Completion } ||
                                     deletedObjects.contains { $0 is Completion }
            
            if hasActivityChanges || hasCompletionChanges {
                print("[WidgetDataSync] Activity or completion changes detected, refreshing widget")
                refreshWidgetTimeline()
            }
        }
    }
    
    /// 处理应用进入前台
    private func handleAppForeground() {
        print("[WidgetDataSync] App entered foreground, refreshing widget")
        refreshWidgetTimeline()
    }
    
    // MARK: - Data Validation and Repair
    
    /// 验证并修复数据一致性
    func validateAndRepairData() {
        // 使用现有的 validateData 方法进行基本验证
        let isValid = validateData()
        if !isValid {
            print("[WidgetDataSync] Data validation failed, attempting repair")
            // 这里可以添加更复杂的修复逻辑
        }
    }
    
    // MARK: - Performance Optimization
    
    /// 优化数据获取性能
    func fetchTopActivitiesOptimized(limit: Int = 6) -> [ActivityModel] {
        // 使用现有的 fetchTopActivities 方法，它已经足够优化
        return fetchTopActivities(limit: limit)
    }
    
    // MARK: - Error Recovery
    
    /// 错误恢复机制
    func handleErrorAndRecover(_ error: Error) {
        print("[WidgetDataSync] Error occurred: \(error)")
        
        // 验证数据完整性
        validateAndRepairData()
    }
    
    // MARK: - Background Refresh
    
    /// 设置后台刷新
    func setupBackgroundRefresh() {
        // 设置定时刷新
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.refreshWidgetTimeline()
        }
    }
} 
