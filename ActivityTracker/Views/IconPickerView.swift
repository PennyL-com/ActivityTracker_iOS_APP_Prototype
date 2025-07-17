import SwiftUI

struct IconPickerView: View {
    // 只暴露选中的 emoji
    @Binding var selectedEmoji: String
    var onSelect: (() -> Void)? = nil

    // 内部状态
    @State private var emojiCategories: [String] = []
    @State private var emojiDict: [String: [EmojiItem]] = [:]
    @State private var categoryIcons: [String: String] = [
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
    @State private var selectedCategory: String = ""

    var body: some View {
        VStack {
            Picker("Categroy", selection: $selectedCategory) {
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
                                onSelect?()
                            }
                    }
                }
                .padding()
            }
        }
        .padding(.top)
        .onAppear {
            let allEmojis = EmojiLoader.loadEmojis()
            let grouped = Dictionary(grouping: allEmojis, by: { $0.category })
            emojiDict = grouped
            emojiCategories = grouped.keys.sorted()
            selectedCategory = emojiCategories.first ?? ""
            if selectedEmoji.isEmpty, let first = grouped[selectedCategory]?.first {
                selectedEmoji = first.emoji
            }
        }
    }
}
