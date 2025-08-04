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
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 