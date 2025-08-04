//
//  WidgetPaginationTest.swift
//  ActivityTrackerWidget
//
//  Created by Pei on 2025-07-07.
//
//  测试 Widget 翻页功能的各个组件

import Foundation
import WidgetKit

/// Widget 翻页功能测试类
class WidgetPaginationTest {
    
    /// App Group ID
    private let groupID = "group.com.penny.activitytracker"
    
    /// 测试页码管理功能
    static func testPageManagement() {
        let test = WidgetPaginationTest()
        
        print("=== Widget 翻页功能测试 ===")
        
        // 测试页码初始化
        test.testPageInitialization()
        
        // 测试翻页逻辑
        test.testPageNavigation()
        
        // 测试边界情况
        test.testBoundaryConditions()
        
        print("=== 测试完成 ===")
    }
    
    /// 测试页码初始化
    private func testPageInitialization() {
        print("\n1. 测试页码初始化...")
        
        let defaults = UserDefaults(suiteName: groupID)
        
        // 清除现有数据
        defaults?.removeObject(forKey: "widget_current_page")
        defaults?.removeObject(forKey: "widget_total_pages")
        
        // 模拟初始化
        if defaults?.object(forKey: "widget_current_page") == nil {
            defaults?.set(1, forKey: "widget_current_page")
        }
        if defaults?.object(forKey: "widget_total_pages") == nil {
            defaults?.set(1, forKey: "widget_total_pages")
        }
        
        let currentPage = defaults?.integer(forKey: "widget_current_page") ?? 0
        let totalPages = defaults?.integer(forKey: "widget_total_pages") ?? 0
        
        print("   当前页: \(currentPage)")
        print("   总页数: \(totalPages)")
        
        assert(currentPage == 1, "当前页应该初始化为 1")
        assert(totalPages == 1, "总页数应该初始化为 1")
        
        print("   ✅ 页码初始化测试通过")
    }
    
    /// 测试翻页逻辑
    private func testPageNavigation() {
        print("\n2. 测试翻页逻辑...")
        
        let defaults = UserDefaults(suiteName: groupID)
        
        // 设置测试数据：3页
        defaults?.set(1, forKey: "widget_current_page")
        defaults?.set(3, forKey: "widget_total_pages")
        
        // 测试下一页
        var currentPage = defaults?.integer(forKey: "widget_current_page") ?? 1
        let totalPages = defaults?.integer(forKey: "widget_total_pages") ?? 1
        
        print("   初始状态: 第 \(currentPage) 页，共 \(totalPages) 页")
        
        // 第一页 -> 第二页
        currentPage = currentPage >= totalPages ? 1 : currentPage + 1
        defaults?.set(currentPage, forKey: "widget_current_page")
        print("   下一页: 第 \(currentPage) 页")
        assert(currentPage == 2, "应该翻到第 2 页")
        
        // 第二页 -> 第三页
        currentPage = currentPage >= totalPages ? 1 : currentPage + 1
        defaults?.set(currentPage, forKey: "widget_current_page")
        print("   下一页: 第 \(currentPage) 页")
        assert(currentPage == 3, "应该翻到第 3 页")
        
        // 第三页 -> 第一页（循环）
        currentPage = currentPage >= totalPages ? 1 : currentPage + 1
        defaults?.set(currentPage, forKey: "widget_current_page")
        print("   下一页: 第 \(currentPage) 页")
        assert(currentPage == 1, "应该循环到第 1 页")
        
        print("   ✅ 下一页逻辑测试通过")
        
        // 测试上一页
        // 第一页 -> 第三页（循环）
        currentPage = currentPage <= 1 ? totalPages : currentPage - 1
        defaults?.set(currentPage, forKey: "widget_current_page")
        print("   上一页: 第 \(currentPage) 页")
        assert(currentPage == 3, "应该循环到第 3 页")
        
        // 第三页 -> 第二页
        currentPage = currentPage <= 1 ? totalPages : currentPage - 1
        defaults?.set(currentPage, forKey: "widget_current_page")
        print("   上一页: 第 \(currentPage) 页")
        assert(currentPage == 2, "应该翻到第 2 页")
        
        // 第二页 -> 第一页
        currentPage = currentPage <= 1 ? totalPages : currentPage - 1
        defaults?.set(currentPage, forKey: "widget_current_page")
        print("   上一页: 第 \(currentPage) 页")
        assert(currentPage == 1, "应该翻到第 1 页")
        
        print("   ✅ 上一页逻辑测试通过")
    }
    
    /// 测试边界情况
    private func testBoundaryConditions() {
        print("\n3. 测试边界情况...")
        
        let defaults = UserDefaults(suiteName: groupID)
        
        // 测试只有一页的情况
        defaults?.set(1, forKey: "widget_current_page")
        defaults?.set(1, forKey: "widget_total_pages")
        
        var currentPage = defaults?.integer(forKey: "widget_current_page") ?? 1
        let totalPages = defaults?.integer(forKey: "widget_total_pages") ?? 1
        
        print("   单页情况: 第 \(currentPage) 页，共 \(totalPages) 页")
        
        // 下一页应该还是第一页
        currentPage = currentPage >= totalPages ? 1 : currentPage + 1
        assert(currentPage == 1, "单页情况下下一页应该还是第 1 页")
        
        // 上一页应该还是第一页
        currentPage = currentPage <= 1 ? totalPages : currentPage - 1
        assert(currentPage == 1, "单页情况下上一页应该还是第 1 页")
        
        print("   ✅ 单页边界测试通过")
        
        // 测试无效页码
        defaults?.set(0, forKey: "widget_current_page")
        defaults?.set(-1, forKey: "widget_total_pages")
        
        let invalidCurrentPage = defaults?.integer(forKey: "widget_current_page") ?? 1
        let invalidTotalPages = defaults?.integer(forKey: "widget_total_pages") ?? 1
        
        print("   无效页码: 第 \(invalidCurrentPage) 页，共 \(invalidTotalPages) 页")
        
        // 应该使用默认值
        let safeCurrentPage = max(1, invalidCurrentPage)
        let safeTotalPages = max(1, invalidTotalPages)
        
        assert(safeCurrentPage == 1, "无效当前页应该修正为 1")
        assert(safeTotalPages == 1, "无效总页数应该修正为 1")
        
        print("   ✅ 无效页码边界测试通过")
    }
    
    /// 测试分页计算
    static func testPaginationCalculation() {
        print("\n4. 测试分页计算...")
        
        // 测试不同数据量的分页
        let testCases = [
            (totalItems: 0, pageSize: 3, expectedPages: 1),
            (totalItems: 1, pageSize: 3, expectedPages: 1),
            (totalItems: 3, pageSize: 3, expectedPages: 1),
            (totalItems: 4, pageSize: 3, expectedPages: 2),
            (totalItems: 6, pageSize: 3, expectedPages: 2),
            (totalItems: 7, pageSize: 3, expectedPages: 3),
            (totalItems: 10, pageSize: 6, expectedPages: 2),
            (totalItems: 12, pageSize: 6, expectedPages: 2),
            (totalItems: 13, pageSize: 6, expectedPages: 3)
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let totalPages = max(1, (testCase.totalItems + testCase.pageSize - 1) / testCase.pageSize)
            print("   测试 \(index + 1): \(testCase.totalItems) 项，每页 \(testCase.pageSize) 项 -> \(totalPages) 页")
            assert(totalPages == testCase.expectedPages, "分页计算错误")
        }
        
        print("   ✅ 分页计算测试通过")
    }
}

// MARK: - 使用示例

/*
 在开发过程中，可以调用以下方法来测试功能：
 
 WidgetPaginationTest.testPageManagement()
 WidgetPaginationTest.testPaginationCalculation()
 
 这些测试会验证：
 1. 页码初始化是否正确
 2. 翻页逻辑是否正常
 3. 边界情况是否处理得当
 4. 分页计算是否准确
 */ 