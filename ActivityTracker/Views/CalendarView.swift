import SwiftUI
import CoreData

// 日历视图，展示一个月的日历和打卡分布，支持切换月份和查看某天详情。
//
// 主要功能：
// - 展示当前月份的日历，标记有完成记录的日期
// - 支持左右切换月份
// - 点击有完成记录的日期可弹出详情页（DateDetailView）
// - 支持外部传入完成日期，便于复用
//
// 用于主 界面展示用户的打卡情况
struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext // CoreData 上下文，用于数据获取
    @State private var selectedDate = Date() // 当前选中的日期（单选模式）
    @State private var showDateDetail = false // 控制详情页弹窗显示
    // 新增：多选支持
    var selectedDates: Binding<[Date]>? = nil // 可选，外部传入多选日期绑定
    
    // 新增：外部传入的完成日期
    var externalCompletionDates: [Date]? = nil // 可选，外部传入已完成的日期
    
    var isEditing: Bool = false
    var pendingAddDates: Binding<Set<Date>>? = nil
    var pendingRemoveDates: Binding<Set<Date>>? = nil
    var activityCompletionDates: [Date]? = nil
    /// 是否显示空白日历（不高亮任何已完成日期）
    var isBlankCalendar: Bool = false
    
    private let calendar = Calendar.current // 日历对象，便于日期计算
    
    // 只读属性，优先用外部传入
    private var completionDates: Set<Date> {
        if isBlankCalendar {
            return []
        }
        if let ext = activityCompletionDates {
            return Set(ext.map { calendar.startOfDay(for: $0) })
        } else if let ext = externalCompletionDates {
            return Set(ext.map { calendar.startOfDay(for: $0) })
        } else {
            // 否则从 CoreData 获取所有完成记录
            let request: NSFetchRequest<Completion> = Completion.fetchRequest()
            if let completions = try? viewContext.fetch(request) {
                return Set(completions.compactMap { $0.completedDate }.map { calendar.startOfDay(for: $0) })
            }
            return []
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 月份切换按钮 TODO这两个个月份切换按钮在上一层的ActivityDetailView不管用
            HStack(spacing: 16) {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .padding(6)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                Spacer()
                Text(monthYearString)
                    .font(.headline)
                Spacer()
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .padding(6)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 8)
            // 星期标题
            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            // 日历网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        let day = calendar.startOfDay(for: date)
                        let isCompleted = completionDates.contains(day)
                        let isPendingAdd = pendingAddDates?.wrappedValue.contains(day) ?? false
                        let isPendingRemove = pendingRemoveDates?.wrappedValue.contains(day) ?? false

                        DayCell(
                            date: date,
                            state: cellState(isCompleted: isCompleted, isPendingAdd: isPendingAdd, isPendingRemove: isPendingRemove)
                        )
                        .onTapGesture {
                            if isEditing {
                                if isCompleted {
                                    // 已有记录，标记为待删除
                                    if isPendingRemove {
                                        pendingRemoveDates?.wrappedValue.remove(day)
                                    } else {
                                        pendingRemoveDates?.wrappedValue.insert(day)
                                    }
                                } else {
                                    // 没有记录，标记为待添加
                                    if isPendingAdd {
                                        pendingAddDates?.wrappedValue.remove(day)
                                    } else {
                                        pendingAddDates?.wrappedValue.insert(day)
                                    }
                                }
                            } else if let binding = selectedDates {
                                // 多选模式：点击切换选中状态
                                if let idx = binding.wrappedValue.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
                                    binding.wrappedValue.remove(at: idx)
                                } else {
                                    binding.wrappedValue.append(date)
                                }
                            } else {
                                // 单选模式：点击选中并弹出详情（如有完成记录）
                                selectedDate = date
                                if completionDates.contains(calendar.startOfDay(for: date)) {
                                    showDateDetail = true
                                }
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 32) // 占位空格
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.95))
                .shadow(color: Color(.black).opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .sheet(isPresented: $showDateDetail) {
            DateDetailView(selectedDate: selectedDate) // 弹出详情页
        }
    }
    
    // MARK: - 计算属性
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedDate) // 当前显示的年月
    }
    
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        // 调整顺序，让周日在前
        return Array(symbols[0..<1]) + Array(symbols[1..<symbols.count])
    }
    
    private var daysInMonth: [Date?] {
        // 计算本月显示的所有日期（含前后补齐）
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate // 本月第一天
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate   // 本月最后一天的下一天
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth // 本月第一天所在周的周日（或周一，取决于地区设置）
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: endOfMonth)?.end ?? endOfMonth         // 本月最后一天所在周的周末的下一天
        var dates: [Date?] = [] // 用于存放日历格子的日期
        var currentDate = startOfWeek // 从本月第一天所在周的起始日开始
        while currentDate < endOfWeek { // 遍历到本月最后一天所在周的结束日
            if calendar.isDate(currentDate, equalTo: startOfMonth, toGranularity: .month) {
                dates.append(currentDate) // 属于本月，加入日期
            } else {
                dates.append(nil) // 不属于本月，用 nil 占位，方便日历对齐
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate // 日期加一天，继续循环
        }
        return dates // 返回所有格子的日期（含占位）
    }
    
    // MARK: - 方法
    
    private func previousMonth() {
        // 切换到上一个月
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextMonth() {
        // 切换到下一个月
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    // MARK: - 统计计算
    
    private var monthlyCompletionCount: Int {
        // 统计本月完成次数
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        request.predicate = NSPredicate(format: "completedDate >= %@ AND completedDate < %@", startOfMonth as NSDate, endOfMonth as NSDate)
        do {
            return try viewContext.count(for: request)
        } catch {
            print("计算月度完成次数失败: \(error)")
            return 0
        }
    }
    
    private var currentStreak: Int {
        // 计算连续打卡天数
        let sortedDates = completionDates.sorted(by: >)
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        return streak
    }
}

// MARK: - 日期单元格视图

enum DayCellState { case normal, completed, pendingAdd, pendingRemove, selected }
func cellState(isCompleted: Bool, isPendingAdd: Bool, isPendingRemove: Bool) -> DayCellState {
    if isPendingRemove { return .pendingRemove }
    if isPendingAdd { return .pendingAdd }
    if isCompleted { return .completed }
    return .normal
}

struct DayCell: View {
    let date: Date // 单元格对应的日期
    let state: DayCellState // 单元格状态
    private let calendar = Calendar.current
    var body: some View {
        ZStack {
            switch state {
            case .selected:
                Circle()
                    .fill(Color.accentColor.opacity(0.7)) // 选中高亮
                    .frame(width: 32, height: 32)
            case .pendingAdd:
                Circle()
                    .fill(Color.accentColor.opacity(0.18)) // 待添加的淡色背景
                    .frame(width: 32, height: 32)
            case .pendingRemove:
                Circle()
                    .fill(Color.red.opacity(0.18)) // 待删除的淡色背景
                    .frame(width: 32, height: 32)
            case .completed:
                Circle()
                    .fill(Color.accentColor.opacity(0.18)) // 有完成记录的淡色背景
                    .frame(width: 32, height: 32)
            case .normal:
                Circle()
                    .fill(Color.clear) // 普通状态
                    .frame(width: 32, height: 32)
            }
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(state == .selected ? .white : (state == .completed ? .accentColor : .primary)) // 字体颜色根据状态变化
        }
        .frame(height: 32)
    }
}

#Preview {
    CalendarView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} // 预览 