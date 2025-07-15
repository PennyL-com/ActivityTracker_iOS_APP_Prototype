import SwiftUI
import CoreData

struct ActivityCardView: View {

    @ObservedObject var activity: Activity // 要显示的活动对象
    // @State var isCompletedToday: Bool // 标记今天是否已完成该活动 Altered
    let onComplete: () -> Void // 完成活动的回调函数 这5个方法是在dashboardview中定义的
    let onEdit: () -> Void // 编辑活动的回调函数
    let onDelete: () -> Void // 删除活动的回调函数
    let onTapCard: () -> Void // 点击卡片的回调函数
    let onTapCheck: () -> Void // 点击打钩按钮的回调函数

    var body: some View {
        let _ = print("ActivityCardView: \(activity.name ?? "") isCompleted = \(activity.isCompleted)")
        
        HStack(alignment: .center, spacing: 16) { // 水平布局，包含活动图标、信息和操作按钮
            ZStack { // 活动图标区域圆形和icon重叠
                Circle() // icon灰色的圆形背景
                    .fill(Color(.systemGray5)) // 使用系统灰色作为背景
                    .frame(width: 48, height: 48)
                Image(systemName: activity.iconName ?? "circle") // 活动图标，如果没有图标则使用默认圆形
                    .font(.system(size: 28))
            }
            VStack(alignment: .leading, spacing: 4) { // 活动信息区域
                Text(activity.name ?? "") // 活动名称
                    .font(.headline)
                Text("Last done: \(daysSinceLastCompletion()) days ago") // 显示距离上次完成的天数 
                    .font(.subheadline)
                    .foregroundColor(.secondary) // 使用次要颜色
            }
            Spacer() // 弹性空间，将按钮推到右侧
            // 完成按钮
            Button(action: {
                // 点击按钮时的逻辑
                if !activity.isCompleted {
                    activity.isCompleted = true
                    onTapCheck()
                }
            }) {
                // 按钮的显示内容
                ZStack {
                    // 按钮背景 
                    Circle()
                        .fill(activity.isCompleted ? .white : Color(.systemGray5))
                        .frame(width: 32, height: 32)
                    // 按钮图标 
                    Image(systemName: activity.isCompleted ? "checkmark.circle" : "checkmark")
                        .foregroundColor(activity.isCompleted ? Color(.systemBlue) : .white)
                        .font(.system(size: 20, weight: .bold))
                    
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(activity.isCompleted)
            .contentShape(Circle())
            .simultaneousGesture( // 同时手势，防止事件冲突
                TapGesture().onEnded { } // 空的手势
            )
        }
        .padding() // 添加内边距
        .background(Color.white) // 白色背景
        .cornerRadius(18) // 圆角半径
        .shadow(color: Color(.black).opacity(0.04), radius: 6, x: 0, y: 2) // 添加阴影效果
        .contentShape(Rectangle()) // 设置整个卡片为可点击区域 TODO：点击区域是否跟button冲突？
        .onTapGesture { // 点击卡片手势
            onTapCard() // 点击卡片时触发回调 具体定义在dashboardView中
        }
        .contextMenu { // 长按显示上下文菜单
            Button(action: onEdit) { // 编辑选项
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) { // 删除选项，使用破坏性样式
                Label("Delete", systemImage: "trash")// TODO：ondelete会把相关数据删掉然后refresh，于是没有定义样式的必要，以后可以考虑添加到临时删除的列表
            }
        }
    }
    
    // TODO：跟DashboardView的逻辑重复，应该抽取一个函数
    func daysSinceLastCompletion() -> Int { // 计算距离上次完成的天数
        let completions = (activity.completions as? Set<Completion>)?.sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) } // 获取活动的所有完成记录，按完成日期降序排列
        guard let last = completions?.first?.completedDate else { return -1 } // 获取最近的完成记录，如果没有则返回-1
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? -1 // 计算从上次完成到现在的天数
    }

}


#Preview {
    let context = PersistenceController.preview.container.viewContext // 创建预览用的 Core Data 上下文
    let mockActivity = Activity(context: context) // 创建模拟活动数据
    mockActivity.id = UUID() // 设置唯一标识符
    mockActivity.name = "Meditation" // 设置活动名称
    mockActivity.iconName = "leaf.fill" // 设置图标名称
    mockActivity.category = "Health" // 设置活动类别
    mockActivity.createdDate = Date() // 设置创建日期
    
    // 添加模拟的完成记录
    let mockCompletion = Completion(context: context) // 创建模拟完成记录
    mockCompletion.id = UUID() // 设置唯一标识符
    mockCompletion.completedDate = Calendar.current.date(byAdding: .day, value: -3, to: Date()) // 设置为3天前完成
    mockCompletion.source = "app" // 设置完成来源
    mockCompletion.activity = mockActivity // 建立与活动的关联关系
    
    return ActivityCardView( // 返回预览视图
        activity: mockActivity, // 传入模拟活动
        onComplete: { print("not completed") }, // 完成回调
        onEdit: { print("✏️") }, // 编辑回调
        onDelete: { print("🗑️") }, // 删除回调
        onTapCard: { print("👆") },
        onTapCheck:{ print("not checked")}// 点击卡片回调
    )
    .environment(\.managedObjectContext, context) // 注入 Core Data 上下文
    .padding() // 添加内边距
}

