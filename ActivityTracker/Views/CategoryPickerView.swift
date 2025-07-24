import SwiftUI
import CoreData

// 可复用的分类选择器
struct CategoryPickerView: View {
    @Binding var selection: Category?
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var categories: [Category] = []
    @State private var showEditCategory = false
    @State private var editingCategory: Category? = nil
    @State private var editingCategoryName: String = ""
    
    var body: some View {
        VStack {
            Picker("选择分类", selection: $selection) {
                // 其他已存在分类
                ForEach(categories) { cat in
                    Text(cat.name ?? "-")
                        .tag(cat)
                }
                // “Custom Category”选项
                Text("Custom Category").tag(nil as Category?)
            }
            .tint(.black)
            .onChange(of: selection) { newValue in
                print("Picker changed: \(String(describing: newValue))")
                if newValue == nil {
                    showAddCategory = true
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet(
                    newCategoryName: $newCategoryName,
                    onConfirm: {
                        guard !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let newCat = ActivityDataManager.shared.createCategory(name: newCategoryName)
                        categories = ActivityDataManager.shared.fetchCategories()
                        selection = newCat
                        showAddCategory = false
                        newCategoryName = ""
                    },
                    onCancel: {
                        showAddCategory = false
                        newCategoryName = ""
                    }
                )
            }
            .onAppear {
                ActivityDataManager.shared.ensureDefaultCategories()
                categories = ActivityDataManager.shared.fetchCategories()
                if selection == nil {
                    // 默认选中 "Hobby"
                    selection = categories.first(where: { $0.name == "Hobby" })
                }
            }
        }
        .sheet(isPresented: $showEditCategory) {
            EditCategorySheet(
                editingCategoryName: $editingCategoryName,
                onSave: {
                    if let cat = editingCategory, !editingCategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                        cat.name = editingCategoryName
                        ActivityDataManager.shared.save()
                        categories = ActivityDataManager.shared.fetchCategories()
                        if selection?.objectID == cat.objectID {
                            selection = cat
                        }
                    }
                    showEditCategory = false
                    editingCategory = nil
                    editingCategoryName = ""
                },
                onCancel: {
                    showEditCategory = false
                    editingCategory = nil
                    editingCategoryName = ""
                }
            )
        }
    }
}

struct AddCategorySheet: View {
    @Binding var newCategoryName: String
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("新建分类")
                .font(.headline)
            TextField("请输入分类名称", text: $newCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("确定", action: onConfirm)
            Button("取消", action: onCancel)
        }
        .padding()
    }
}

struct EditCategorySheet: View {
    @Binding var editingCategoryName: String
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("编辑分类名称")
                .font(.headline)
            TextField("请输入新名称", text: $editingCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("保存", action: onSave)
            Button("取消", action: onCancel)
        }
        .padding()
    }
}