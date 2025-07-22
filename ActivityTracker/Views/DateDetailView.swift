import SwiftUI
import CoreData

// 日期详情视图，展示某一天的所有完成记录，并支持编辑活动分类。
//
// 主要功能：
// - 展示选中日期的所有打卡/完成记录
// - 支持编辑活动的分类
// - 显示活动的图标、名称、描述、完成时间和来源等信息
//
// 用于从日历视图点击某天后弹出，查看和管理当天的详细打卡内容
struct DateDetailView: View {
    let selectedDate: Date // 选中的日期
    @Environment(\.managedObjectContext) private var viewContext // CoreData 上下文
    @Environment(\.presentationMode) var presentationMode // 控制视图的显示/隐藏
    @State private var completions: [Completion] = [] // 当前日期的完成记录
    
    private let calendar = Calendar.current // 当前日历对象
    
    var body: some View {
        NavigationView {
            VStack {
                if completions.isEmpty {
                    // 没有完成记录时的占位视图
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No records for this day")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Select other date to view records")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 有完成记录时，列表展示
                    List {
                        Section(header: Text("History")) {
                            ForEach(completions, id: \.id) { completion in
                                CompletionRowView(completion: completion) // 单条完成记录行
                            }
                        }
                    }
                }
            }
            .navigationTitle(dateString) // 标题为日期字符串
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Complete") {
                        presentationMode.wrappedValue.dismiss() // 关闭详情视图
                    }
                }
            }
            .onAppear {
                loadCompletionsForDate() // 视图出现时加载数据
            }
        }
    }
    
    private var dateString: String {
        // 将日期格式化为“yyyy年M月d日”
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    private func loadCompletionsForDate() {
        // 查询选中日期的所有完成记录
        let startOfDay = calendar.startOfDay(for: selectedDate) // 当天0点
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay // 次日0点
        
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        request.predicate = NSPredicate(format: "completedDate >= %@ AND completedDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "completedDate", ascending: false)]
        
        do {
            completions = try viewContext.fetch(request) // 获取数据
        } catch {
            print("Failed to load completions for date: \(error)")
            completions = []
        }
    }
}

// MARK: - 完成记录行视图

struct CompletionRowView: View {
    @ObservedObject var completion: Completion // 单条完成记录
    // 移除编辑相关状态
    
    var body: some View {
        HStack(spacing: 12) {
            // 活动图标
            if let activity = completion.activity {
                if let iconName = activity.iconName, !iconName.isEmpty {
                    if iconName.isSingleEmoji {
                        Text(iconName)
                            .font(.title2)
                    } else {
                        Image(systemName: iconName)
                            .font(.title2)
                            .foregroundColor(Color.accentColor)
                    }
                } else {
                    Image(systemName: "circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.accentColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // 活动名称
                if let activity = completion.activity {
                    Text(activity.name ?? "Unknown activity")
                        .font(.headline)
                        .fontWeight(.medium)
                    // 只读展示分类
                    HStack(spacing: 4) {
                        Text(activity.category ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        // 移除编辑按钮
                    }
                    // 活动描述
                    if let details = activity.optionalDetails, !details.isEmpty {
                        Text(details)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            Spacer()
            
            // 完成时间和来源
            VStack(alignment: .trailing, spacing: 4) {
                if let completedDate = completion.completedDate {
                    Text(timeString(from: completedDate)) // 完成时间（时:分）
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 完成来源
                if let source = completion.source {
                    Text(source == "app" ? "From App" : source == "widget" ? "From Widget" : source)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(Color.accentColor)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func timeString(from date: Date) -> String {
        // 时间格式化为“HH:mm”
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // 创建模拟数据
    let activity = Activity(context: context)
    activity.id = UUID()
    activity.name = "冥想"
    activity.category = "健康"
    activity.iconName = "🧘‍♀️"
    
    let completion = Completion(context: context)
    completion.id = UUID()
    completion.completedDate = Date()
    completion.source = "app"
    completion.activity = activity
    
    return DateDetailView(selectedDate: Date())
        .environment(\.managedObjectContext, context)
} 