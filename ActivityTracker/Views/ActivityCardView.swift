import SwiftUI

struct ActivityCardView: View {

    let activity: Activity // 要显示的活动对象
    let isCompletedToday: Bool // 标记今天是否已完成该活动 Altered
    let onComplete: () -> Void // 完成活动的回调函数 这4个方法是在dashboardview中定义的
    let onEdit: () -> Void // 编辑活动的回调函数
    let onDelete: () -> Void // 删除活动的回调函数
    let onTapCard: () -> Void // 点击卡片的回调函数
    //TODO：应该添加一个点击打钩按钮事件
  
    var body: some View {
        HStack(alignment: .center, spacing: 16) { // 水平布局，包含活动图标、信息和操作按钮
            ZStack { // 活动图标区域 TODO：为啥要用Zstack？
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
            Button(action: { // 完成按钮
                if !isCompletedToday { // 默认是false TODO：这个逻辑应该是点击后把这个bool变成true，然后改变样式；如果已经是true就没动作
                    onComplete()//TODO：原本是false变成true之后才调用onComplete
                }
            }) {
                ZStack { // 按钮内容
                    Circle() // 按钮背景圆形
                        //TODO：已测试主题色紫色看来这个 isCompletedToday 是false，所以是灰色, 但是按钮显示已打钩，说明这个逻辑有问题，可能跟dashboardview的重复的方法有关
                        .fill(isCompletedToday ? Color.accentColor : Color(.systemGray5)) // 已完成时使用主题色，未完成时使用灰色
                        .frame(width: 32, height: 32)
                    Image(systemName: isCompletedToday ? "checkmark" : "checkmark.circle") // 按钮图标 TODO：打钩按钮变更逻辑在这，差一个赋值isCompletedToday的逻辑
                        .foregroundColor(isCompletedToday ? .white : .accentColor) // 已完成时图标为白色，未完成时为主题色
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .buttonStyle(PlainButtonStyle()) // 使用无样式按钮
            .disabled(isCompletedToday) // 今天已完成时禁用按钮 
            .contentShape(Circle()) // 设置点击区域为圆形
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
        isCompletedToday: false, // 设置为今天未完成
        onComplete: { print("✅") }, // 完成回调
        onEdit: { print("✏️") }, // 编辑回调
        onDelete: { print("🗑️") }, // 删除回调
        onTapCard: { print("👆") } // 点击卡片回调
    )
    .environment(\.managedObjectContext, context) // 注入 Core Data 上下文
    .padding() // 添加内边距
}

