//
//  AppIntent.swift
//  ActivityTrackerWidget
//
//  Created by Pei on 2025-07-07.
//

import WidgetKit
import AppIntents

/// 完成活动的Intent
struct CompleteActivityIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Activity"
    static var description: LocalizedStringResource = "Mark an activity as completed"
    
    @Parameter(title: "Activity ID")
    var activityID: String
    
    init() {}
    
    init(activityID: String) {
        self.activityID = activityID
    }
    
    func perform() async throws -> some IntentResult {
        // 使用WidgetDataManager来完成活动
        let success = WidgetDataManager.shared.markActivityComplete(activityID: UUID(uuidString: activityID) ?? UUID())
        
        if success {
            // 强制刷新小组件时间线，确保状态立即更新
            WidgetDataManager.shared.forceRefreshWidget()
            return .result()
        } else {
            throw Error.failedToComplete
        }
    }
    
    enum Error: Swift.Error, CustomLocalizedStringResourceConvertible {
        case failedToComplete
        
        var localizedStringResource: LocalizedStringResource {
            switch self {
            case .failedToComplete:
                return "Failed to complete activity"
            }
        }
    }
}

/// 下一页Intent
struct NextPageIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Page"
    static var description: LocalizedStringResource = "Show next page of activities"
    
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.penny.activitytracker")
        let currentPage = defaults?.integer(forKey: "widget_current_page") ?? 1
        let totalPages = defaults?.integer(forKey: "widget_total_pages") ?? 1
        
        // 只有在不是最后一页时才允许翻页
        if currentPage < totalPages {
            let newPage = currentPage + 1
            defaults?.set(newPage, forKey: "widget_current_page")
            
            // 强制刷新小组件时间线
            WidgetDataManager.shared.forceRefreshWidget()
        }
        
        return .result()
    }
}

/// 上一页Intent
struct PreviousPageIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Page"
    static var description: LocalizedStringResource = "Show previous page of activities"
    
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.penny.activitytracker")
        let currentPage = defaults?.integer(forKey: "widget_current_page") ?? 1
        let totalPages = defaults?.integer(forKey: "widget_total_pages") ?? 1
        
        // 只有在不是第一页时才允许翻页
        if currentPage > 1 {
            let newPage = currentPage - 1
            defaults?.set(newPage, forKey: "widget_current_page")
            
            // 强制刷新小组件时间线
            WidgetDataManager.shared.forceRefreshWidget()
        }
        
        return .result()
    }
}
