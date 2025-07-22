import Foundation
import CoreData

struct TestDataGenerator {
    static func generateSampleData(context: NSManagedObjectContext) {
        // 创建一些示例活动
        let activities = [
            ("冥想", "Health", "🧘‍♀️"),
            ("跑步", "Health", "🏃‍♂️"),
            ("读书", "Education", "📚"),
            ("写代码", "Hobby", "💻"),
            ("遛狗", "Pet", "🐕")
        ]
        
        var createdActivities: [Activity] = []
        
        for (name, category, icon) in activities {
            let activity = Activity(context: context)
            activity.id = UUID()
            activity.name = name
            activity.category = category
            activity.iconName = icon
            activity.createdDate = Date()
            activity.isCompleted = false
            createdActivities.append(activity)
        }
        
        // 为每个活动生成一些随机的完成记录
        let calendar = Calendar.current
        let today = Date()
        
        for activity in createdActivities {
            // 随机生成过去30天内的完成记录
            for _ in 0..<Int.random(in: 3...8) {
                let randomDaysAgo = Int.random(in: 0...30)
                if let randomDate = calendar.date(byAdding: .day, value: -randomDaysAgo, to: today) {
                    let completion = Completion(context: context)
                    completion.id = UUID()
                    completion.completedDate = randomDate
                    completion.source = Int.random(in: 0...1) == 0 ? "app" : "widget"
                    completion.activity = activity
                }
            }
        }
        
        // 保存到 Core Data
        do {
            try context.save()
            print("测试数据生成成功")
        } catch {
            print("保存测试数据失败: \(error)")
        }
    }
    
    static func clearAllData(context: NSManagedObjectContext) {
        // 删除所有活动
        let activityRequest: NSFetchRequest<NSFetchRequestResult> = Activity.fetchRequest()
        let deleteActivityRequest = NSBatchDeleteRequest(fetchRequest: activityRequest)
        
        // 删除所有完成记录
        let completionRequest: NSFetchRequest<NSFetchRequestResult> = Completion.fetchRequest()
        let deleteCompletionRequest = NSBatchDeleteRequest(fetchRequest: completionRequest)
        
        do {
            try context.execute(deleteActivityRequest)
            try context.execute(deleteCompletionRequest)
            try context.save()
            print("所有数据已清除")
        } catch {
            print("清除数据失败: \(error)")
        }
    }
} 