import Foundation
import CoreData

struct ActivityUtils {
    /// 计算活动自上次完成以来经过的天数
    /// - Parameter activity: 要计算的活动
    /// - Returns: 天数，如果没有完成记录则返回 -1
    static func daysSinceLastCompletion(for activity: Activity) -> Int {
        let completions = (activity.completions as? Set<Completion>)?.sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
        guard let last = completions?.first?.completedDate else { return -1 }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? -1
    }
}
