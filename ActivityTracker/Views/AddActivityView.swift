import SwiftUI
import CoreData

struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var category = "Hobby"
    @State private var optionalDetails = ""
    @State private var priorityRank: Int16 = 0
    @State private var iconName = "star"
    @State private var isCompleted = false // 添加completed状态
    @State private var emojiList: [EmojiItem] = []
    @State private var selectedEmoji: String = ""
    @State private var showEmojiPicker = false
    @State private var emojiCategories: [String] = []
    @State private var selectedCategory: String = ""
    @State private var emojiDict: [String: [EmojiItem]] = [:]
    // 新增：分类到代表emoji的映射
    let categoryIcons: [String: String] = [
        "Smileys & Emotion": "😀",
        "People & Body": "🧑",
        "Animals & Nature": "🐶",
        "Food & Drink": "🍎",
        "Travel & Places": "🚗",
        "Activities": "⚽️",
        "Objects": "💡",
        "Symbols": "❤️",
        "Flags": "🏳️"
    ]
    let categories = ["Hobby", "Health", "Pet", "Home", "Others", "Education"].sorted()
    var onSave: () -> Void
    

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat)
                        }
                    }
                    // Completed状态选择器
                    HStack {
                        Text("Completed Today")
                        Spacer()
                        Toggle("", isOn: $isCompleted)
                    }

                    HStack {
                        Text("Select Icon")
                        Spacer()
                        Button(action: {
                            showEmojiPicker = true
                        }) {
                            Text(selectedEmoji.isEmpty ? "" : selectedEmoji)
                                .font(.largeTitle)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                    }
                    .sheet(isPresented: $showEmojiPicker) {
                        VStack {
                            Picker("分类", selection: $selectedCategory) {
                                ForEach(emojiCategories, id: \.self) { cat in
                                    Text(categoryIcons[cat] ?? "❓")
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding()

                            ScrollView {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                                    ForEach(emojiDict[selectedCategory] ?? [], id: \.emoji) { item in
                                        Text(item.emoji)
                                            .font(.largeTitle)
                                            .frame(width: 44, height: 44)
                                            .background(selectedEmoji == item.emoji ? Color.accentColor.opacity(0.3) : Color.clear)
                                            .cornerRadius(8)
                                            .onTapGesture {
                                                selectedEmoji = item.emoji
                                                showEmojiPicker = false
                                            }
                                    }
                                }
                                .padding()
                            }
                        }
                        .padding(.top)
                    }
                    
                    TextField("Details", text: $optionalDetails)
                }
            }
            .navigationTitle("Add Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("Creating activity: \(name)")
                        print("AddActivityView: isCompleted = \(isCompleted)")
                        let activity = ActivityDataManager.shared.createActivity(
                            name: name,
                            category: category,
                            iconName: selectedEmoji,
                            optionalDetails: optionalDetails.isEmpty ? nil : optionalDetails,
                            createdDate: Date(),
                            isCompleted: isCompleted //所以这里创建activity的时候是会传入isCompleted的
                        )
                        
                        print("Activity created with ID: \(activity.id?.uuidString ?? "nil")")
                        print("Activity created with isCompleted: \(activity.isCompleted)")
                        
                        // 如果用户选择了completed，立即添加完成记录
                        //TODO：source 需要补全completions相关逻辑
                        if isCompleted {
                            _ = ActivityDataManager.shared.addCompletion(to: activity, source: "app")
                            print("Completion record added")
                        }
                        
                        onSave()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                let allEmojis = EmojiLoader.loadEmojis()
                let grouped = Dictionary(grouping: allEmojis, by: { $0.category })
                emojiDict = grouped
                emojiCategories = grouped.keys.sorted()
                selectedCategory = emojiCategories.first ?? ""
                if let first = grouped[selectedCategory]?.first {
                    selectedEmoji = first.emoji
                }
            }
        }
    }
}

#Preview {
    AddActivityView(onSave: {})
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 