import SwiftUI
import CoreData

// 可复用的分类选择器
struct CategoryPickerView: View {
    @Binding var selection: Category?
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    ) var categories: FetchedResults<Category>
    @State private var showEditCategory = false
    @State private var editingCategory: Category? = nil
    @State private var editingCategoryName: String = ""
    @State private var showDuplicateAlert = false
    @State private var showEditDuplicateAlert = false
    
    var body: some View {
        VStack {
            Picker("选择分类", selection: $selection) {
                // 其他已存在分类
                ForEach(categories) { cat in
                    Text(cat.name ?? "-")
                        .tag(cat as Category?)
                }
                // “Custom Category”选项
                Text("Add New Category")
                    .foregroundColor(Color.accentColor)
                    .tag(nil as Category?)
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
                    categories: categories,
                    onConfirm: {
                        let newCat = ActivityDataManager.shared.createCategory(name: newCategoryName)
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
                // ActivityDataManager.shared.ensureDefaultCategories()
                if selection == nil {
                    // 默认选中 "Hobby"
                    selection = categories.first(where: { $0.name == "Hobby" })
                }
            }
        }
        .sheet(isPresented: $showEditCategory) {
            EditCategorySheet(
                editingCategoryName: $editingCategoryName,
                categories: categories,
                editingCategory: editingCategory,
                onSave: {
                    if let cat = editingCategory, !editingCategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                        cat.name = editingCategoryName
                        ActivityDataManager.shared.save()
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
    var categories: FetchedResults<Category>
    var onConfirm: () -> Void
    var onCancel: () -> Void
    @State private var showDuplicateAlert = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Add New Category")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .center)
            TextField("Enter category name", text: $newCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            HStack(spacing: 40) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                Button("Confirm") {
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    if categories.contains(where: { ($0.name ?? "").trimmingCharacters(in: .whitespaces) == trimmed }) {
                        showDuplicateAlert = true
                        return
                    }
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.bottom, 8)
        }
        .padding()
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.black).opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
        .alert(isPresented: $showDuplicateAlert) {
            Alert(title: Text("已存在同名分类"), message: Text("请使用其他名称。"), dismissButton: .default(Text("确定")))
        }
    }
}


struct EditCategorySheet: View {
    @Binding var editingCategoryName: String
    var categories: FetchedResults<Category>
    var editingCategory: Category?
    var onSave: () -> Void
    var onCancel: () -> Void
    @State private var showDuplicateAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("编辑分类名称")
                .font(.headline)
            TextField("请输入新名称", text: $editingCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("保存") {
                let trimmed = editingCategoryName.trimmingCharacters(in: .whitespaces)
                guard let cat = editingCategory, !trimmed.isEmpty else { return }
                if categories.contains(where: { ($0.name ?? "").trimmingCharacters(in: .whitespaces) == trimmed && $0.objectID != cat.objectID }) {
                    showDuplicateAlert = true
                    return
                }
                onSave()
            }
            Button("取消", action: onCancel)
        }
        .padding()
        .alert(isPresented: $showDuplicateAlert) {
            Alert(title: Text("已存在同名分类"), message: Text("请使用其他名称。"), dismissButton: .default(Text("确定")))
        }
    }
}