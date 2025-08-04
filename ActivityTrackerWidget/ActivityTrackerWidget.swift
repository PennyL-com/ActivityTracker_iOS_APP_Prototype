//
//  ActivityTrackerWidget.swift
//  ActivityTrackerWidget
//
//  Created by Pei on 2025-07-07.
//
//  小组件功能说明：
//  1. 默认显示app内dashboard排序过的前6个活动（大尺寸显示8个）
//  2. 每个活动显示：左边打钩按钮，右边分两行显示活动名字和"xx days ago"
//  3. 按钮逻辑和app内一样，点击后同步到CoreData
//  4. 支持中等尺寸和大尺寸两种显示模式
//  5. 使用App Group共享Core Data，确保与主应用数据同步

import WidgetKit
import SwiftUI
import Intents
import CoreData

// MARK: - Entry
struct ActivityEntry: TimelineEntry {
    let date: Date
    let activities: [ActivityModel]
    let currentPage: Int
    let totalPages: Int
}

// MARK: - Timeline Provider
struct ActivityProvider: TimelineProvider {
    func placeholder(in context: Context) -> ActivityEntry {
        ActivityEntry(date: Date(), activities: [], currentPage: 1, totalPages: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (ActivityEntry) -> ()) {
        let isLarge = context.family == .systemLarge
        let activities = WidgetDataManager.shared.fetchActivitiesForWidgetSize(isLarge: isLarge)
        let defaults = UserDefaults(suiteName: "group.com.penny.activitytracker")
        let currentPage = defaults?.integer(forKey: "widget_current_page") ?? 1
        let totalPages = defaults?.integer(forKey: "widget_total_pages") ?? 1
        
        completion(ActivityEntry(date: Date(), activities: activities, currentPage: currentPage, totalPages: totalPages))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ActivityEntry>) -> ()) {
        let isLarge = context.family == .systemLarge
        let activities = WidgetDataManager.shared.fetchActivitiesForWidgetSize(isLarge: isLarge)
        let defaults = UserDefaults(suiteName: "group.com.penny.activitytracker")
        let currentPage = defaults?.integer(forKey: "widget_current_page") ?? 1
        let totalPages = defaults?.integer(forKey: "widget_total_pages") ?? 1
        
        let entry = ActivityEntry(date: Date(), activities: activities, currentPage: currentPage, totalPages: totalPages)
        // 每小时刷新
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}



// MARK: - Widget View
struct ActivityTrackerWidgetEntryView: View {
    var entry: ActivityProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        GeometryReader { geo in
            if entry.activities.isEmpty {
                // 空状态 - 显示简洁的占位符
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(8)
            } else {
                if family == .systemLarge {
                    // 大尺寸布局：显示6条活动，无翻页
                    LargeWidgetLayout(activities: entry.activities)
                } else {
                    // 中尺寸布局：显示3条活动，有翻页
                    MediumWidgetLayout(
                        activities: entry.activities,
                        currentPage: entry.currentPage,
                        totalPages: entry.totalPages
                    )
                }
            }
        }
    }
}

// MARK: - Large Widget Layout
struct LargeWidgetLayout: View {
    let activities: [ActivityModel]
    
    var body: some View {
        VStack(spacing: 8) {
            // 活动列表 - 显示所有6条活动
            ForEach(activities.prefix(6)) { activity in
                ActivityRowView(activity: activity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget Layout
struct MediumWidgetLayout: View {
    let activities: [ActivityModel]
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            // 左侧：活动列表
            VStack(spacing: 4) {
                ForEach(activities.prefix(3)) { activity in
                    ActivityRowView(activity: activity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            
            // 右侧：翻页按钮 - 只在有多页且有数据时显示
            if totalPages > 1 && !activities.isEmpty {
                VStack(spacing: 6) {
                    // 上一页按钮 - 只在不是第一页时显示
                    if currentPage > 1 {
                        Button(intent: PreviousPageIntent()) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // 占位符，保持布局一致
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 28, height: 28)
                    }
                    
                    // 页码指示器
                    Text("\(currentPage)/\(totalPages)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(-90))
                    
                    // 下一页按钮 - 只在不是最后一页时显示
                    if currentPage < totalPages {
                        Button(intent: NextPageIntent()) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // 占位符，保持布局一致
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 28, height: 28)
                    }
                }
                .frame(width: 28)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Activity Row View
struct ActivityRowView: View {
    let activity: ActivityModel
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        HStack(spacing: family == .systemLarge ? 12 : 6) {
            // 左边打钩按钮 - 使用Button和AppIntent
            Button(intent: CompleteActivityIntent(activityID: activity.id.uuidString)) {
                // 按钮的显示内容
                ZStack {
                    // 按钮背景 
                    Circle()
                        .fill(activity.isCompletedToday ? .white : Color(.systemGray5))
                        .frame(width: family == .systemLarge ? 32 : 24, height: family == .systemLarge ? 32 : 24)
                    // 按钮图标 
                    Image(systemName: activity.isCompletedToday ? "checkmark.circle" : "checkmark")
                        .foregroundColor(activity.isCompletedToday ? Color(.systemBlue) : .white)
                        .font(.system(size: family == .systemLarge ? 20 : 14, weight: .bold))
                }
            }
            .disabled(activity.isCompletedToday)
            .buttonStyle(PlainButtonStyle())
            
            // 右边活动信息
            VStack(alignment: .leading, spacing: family == .systemLarge ? 1 : 0) {
                // 上面一行大字写活动名字
                Text(activity.name)
                    .font(.system(size: family == .systemLarge ? 14 : 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // 下面一行小字写xx days ago
                Text(activity.daysSinceCompletion >= 0 ? "\(activity.daysSinceCompletion) days ago" : "Never")
                    .font(.system(size: family == .systemLarge ? 11 : 9))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(height: family == .systemLarge ? nil : 32)
        .padding(.vertical, family == .systemLarge ? 6 : 2)
        .padding(.horizontal, family == .systemLarge ? 10 : 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Widget 配置
struct ActivityTrackerWidget: Widget {
    let kind: String = "ActivityTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActivityProvider()) { entry in
            ActivityTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Activity Tracker")
        .description("Quickly complete and view your top activities.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct ActivityTrackerWidget_Previews: PreviewProvider {
    static var previews: some View {
        let mockActivities = [
            ActivityModel(id: UUID(), name: "Meditation", iconName: "leaf.fill", daysSinceCompletion: 2, isCompletedToday: false),
            ActivityModel(id: UUID(), name: "Exercise", iconName: "figure.run", daysSinceCompletion: 0, isCompletedToday: true),
            ActivityModel(id: UUID(), name: "Reading", iconName: "book.fill", daysSinceCompletion: 5, isCompletedToday: false),
            ActivityModel(id: UUID(), name: "Writing", iconName: "pencil", daysSinceCompletion: 1, isCompletedToday: false),
            ActivityModel(id: UUID(), name: "Coding", iconName: "laptopcomputer", daysSinceCompletion: 3, isCompletedToday: false),
            ActivityModel(id: UUID(), name: "Walking", iconName: "figure.walk", daysSinceCompletion: 0, isCompletedToday: true),
            ActivityModel(id: UUID(), name: "Cooking", iconName: "fork.knife", daysSinceCompletion: 1, isCompletedToday: false),
            ActivityModel(id: UUID(), name: "Drawing", iconName: "pencil.and.outline", daysSinceCompletion: 4, isCompletedToday: false)
        ]
        
        Group {
            ActivityTrackerWidgetEntryView(entry: ActivityEntry(date: Date(), activities: mockActivities, currentPage: 1, totalPages: 3))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")
            
            ActivityTrackerWidgetEntryView(entry: ActivityEntry(date: Date(), activities: mockActivities, currentPage: 2, totalPages: 3))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large")
        }
    }
}


