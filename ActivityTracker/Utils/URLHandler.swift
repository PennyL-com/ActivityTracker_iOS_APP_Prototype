import Foundation
import SwiftUI
import CoreData
#if canImport(WidgetKit)
import WidgetKit
#endif

/// URL处理器 - 处理小组件和应用间的URL交互
class URLHandler: ObservableObject {
    
    /// 处理从小组件或其他来源传入的URL
    func handleURL(_ url: URL) {
        print("[URLHandler] Received URL: \(url)")
        
        guard url.scheme == "activitytracker" else {
            print("[URLHandler] Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch pathComponents.first {
        case "complete":
            handleCompleteActivity(pathComponents: pathComponents)
        case "widget":
            handleWidgetTap()
        default:
            print("[URLHandler] Unknown path: \(pathComponents)")
        }
    }
    
    /// 处理完成活动的URL
    private func handleCompleteActivity(pathComponents: [String]) {
        guard pathComponents.count > 1 else {
            print("[URLHandler] Invalid complete URL format")
            return
        }
        
        let activityIDString = pathComponents[1]
        guard let activityID = UUID(uuidString: activityIDString) else {
            print("[URLHandler] Invalid activity ID: \(activityIDString)")
            return
        }
        
        print("[URLHandler] Completing activity with ID: \(activityID)")
        
        // 使用ActivityDataManager来完成活动
        let dataManager = ActivityDataManager.shared
        
        // 根据activityID查找Activity
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", activityID as CVarArg)
        request.fetchLimit = 1
        
        do {
            let activities = try dataManager.context.fetch(request)
            if let activity = activities.first {
                // 添加完成记录
                dataManager.addCompletion(to: activity, source: "widget")
                print("[URLHandler] Activity completed successfully: \(activity.name ?? "")")
            } else {
                print("[URLHandler] Activity not found with ID: \(activityID)")
            }
        } catch {
            print("[URLHandler] Error finding activity: \(error)")
        }
        
        // 刷新小组件时间线
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        print("[URLHandler] Widget timeline refreshed")
        #endif
    }
    
    /// 处理小组件点击（打开应用）
    private func handleWidgetTap() {
        print("[URLHandler] Widget tapped - app opened")
        // 这里可以添加打开应用时的特殊逻辑
    }
} 