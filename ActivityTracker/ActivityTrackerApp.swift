import SwiftUI
import CoreData
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
struct ActivityTrackerApp: App {
    @StateObject private var urlHandler = URLHandler()
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    urlHandler.handleURL(url)
                }
                .onAppear {
                    // 在视图出现后初始化
                    setupWidgetDataManager()
                    checkDateChangeAndUpdateWidget()
                    ensureDefaultCategories()
                }
        }
    }
    
    /// 设置小组件数据管理器
    private func setupWidgetDataManager() {
        // 验证数据完整性
        #if canImport(WidgetKit)
        // 这里可以添加小组件相关的初始化逻辑
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
    
    /// 确保默认分类存在
    private func ensureDefaultCategories() {
        // 在后台队列中执行，避免阻塞主线程
        DispatchQueue.global(qos: .background).async {
            ActivityDataManager.shared.ensureDefaultCategories()
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 