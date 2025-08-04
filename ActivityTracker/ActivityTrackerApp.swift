import SwiftUI
import CoreData
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
struct ActivityTrackerApp: App {
    @StateObject private var urlHandler = URLHandler()
    
    init() {
        // 初始化小组件数据管理器
        setupWidgetDataManager()
        // 检查日期变化并更新小组件
        checkDateChangeAndUpdateWidget()
    }
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .onOpenURL { url in
                    urlHandler.handleURL(url)
                }
        }
    }
    
    /// 设置小组件数据管理器
    private func setupWidgetDataManager() {
        // 验证数据完整性
        #if canImport(WidgetKit)
        // 这里可以添加小组件相关的初始化逻辑
        print("Widget data manager setup completed")
        #endif
    }
    
    /// 检查日期变化并更新小组件
    private func checkDateChangeAndUpdateWidget() {
        let defaults = UserDefaults(suiteName: "group.com.penny.activitytracker")
        let lastUpdateDate = defaults?.object(forKey: "app_last_update_date") as? Date ?? Date.distantPast
        
        if !Calendar.current.isDateInToday(lastUpdateDate) {
            // 日期已变化，更新小组件
            defaults?.set(Date(), forKey: "app_last_update_date")
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            print("Date changed, widget updated from app")
            #endif
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 