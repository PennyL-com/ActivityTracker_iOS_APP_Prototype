import SwiftUI
import CoreData

struct ActivityCardView: View {

    @ObservedObject var activity: Activity // 要显示的活动对象
    // @State var isCompletedToday: Bool // 标记今天是否已完成该活动 Altered
    let onComplete: () -> Void // 完成活动的回调函数 这5个方法是在dashboardview中定义的
    let onDelete: () -> Void // 删除活动的回调函数
    let onTapCard: () -> Void // 点击卡片的回调函数
    let onSort: () -> Void // 新增：排序按钮回调
    let showSort: Bool // 新增：是否显示排序按钮

    @Environment(\.managedObjectContext) var context // 获取 Core Data 上下文
    @State private var refreshTrigger = UUID() // 用于强制UI刷新
    
    // 新增：判断今天是否已完成
    var isCompletedToday: Bool {
        let _ = refreshTrigger // 依赖刷新触发器
        let completions = (activity.completions as? Set<Completion>) ?? []
        return completions.contains { completion in
            if let date = completion.completedDate {
                return Calendar.current.isDateInToday(date)
            }
            return false
        }
    }

    var body: some View {
        let _ = print("ActivityCardView: \(activity.name ?? "") isCompleted = \(activity.isCompleted)")
        
        HStack(alignment: .center, spacing: 16) { // 水平布局，包含活动图标、信息和操作按钮
            ZStack { // 活动图标区域圆形和icon重叠
                Circle() // icon灰色的圆形背景
                    .fill(Color(.systemGray5)) // 使用系统灰色作为背景
                    .frame(width: 48, height: 48)
                if let icon = activity.iconName, icon.isSingleEmoji {
                    Text(icon)
                        .font(.system(size: 28))
                } else {
                    Image(systemName: activity.iconName ?? "circle") // 活动图标，如果没有图标则使用默认圆形
                        .font(.system(size: 28))
                }
            }
            VStack(alignment: .leading, spacing: 4) { // 活动信息区域
                Text(activity.name ?? "") // 活动名称
                    .font(.headline)
                Text("Last done: \(ActivityUtils.daysSinceLastCompletion(for: activity)) days ago") // 显示距离上次完成的天数 
                    .font(.subheadline)
                    .foregroundColor(.secondary) // 使用次要颜色
            }
            Spacer() // 弹性空间，将按钮推到右侧
            // 完成按钮
            Button(action: {
                onComplete()
                refreshTrigger = UUID() // 立即刷新UI
            }) {
                // 按钮的显示内容
                ZStack {
                    // 按钮背景 
                    Circle()
                        .fill(isCompletedToday ? .white : Color(.systemGray5))
                        .frame(width: 32, height: 32)
                    // 按钮图标 
                    Image(systemName: isCompletedToday ? "checkmark.circle" : "checkmark")
                        .foregroundColor(isCompletedToday ? Color(.systemBlue) : .white)
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isCompletedToday)
            .contentShape(Circle())
            .simultaneousGesture( // 同时手势，防止事件冲突
                TapGesture().onEnded { } // 空的手势
            )
        }
        .padding() // 添加内边距
        .background(Color.white) // 白色背景
        .cornerRadius(18) // 圆角半径
        .shadow(color: Color(.black).opacity(0.04), radius: 6, x: 0, y: 2) // 添加阴影效果
        .contentShape(Rectangle()) 
        .onTapGesture { // 点击卡片手势
            onTapCard() // 点击卡片时触发回调 具体定义在dashboardView中
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if showSort {
                Button(action: onSort) {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .tint(.blue)
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            // 移除了编辑按钮
        }
    }

}


#Preview {
    let context = PersistenceController.preview.container.viewContext // 创建预览用的 Core Data 上下文

    // 创建模拟分类
    let mockCategory = Category(context: context)
    mockCategory.categoryId = UUID()
    mockCategory.name = "Wellness"

    // 创建模拟活动数据
    let mockActivity = Activity(context: context)
    mockActivity.id = UUID()
    mockActivity.name = "Meditation"
    mockActivity.iconName = "leaf.fill"
    mockActivity.belongToCategory = mockCategory // 赋值为关系对象
    mockActivity.createdDate = Date()

    // 添加模拟的完成记录
    let mockCompletion = Completion(context: context)
    mockCompletion.id = UUID()
    mockCompletion.completedDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
    mockCompletion.source = "app"
    mockCompletion.activity = mockActivity

    return ActivityCardView(
        activity: mockActivity,
        onComplete: { print("not completed") },
        onDelete: { print("🗑️") },
        onTapCard: { print("👆") },
        onSort: { print("Sort") },
        showSort: true
    )
    .environment(\.managedObjectContext, context)
    .padding()
}

extension String {
    var isSingleEmoji: Bool {
        return self.count == 1 && self.unicodeScalars.first?.properties.isEmoji == true
    }
}

