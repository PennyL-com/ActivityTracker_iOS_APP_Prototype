import Foundation

struct EmojiLoader {
    static func loadEmojis() -> [EmojiItem] {
        guard let url = Bundle.main.url(forResource: "emoji", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        let decoder = JSONDecoder()
        // 解析 emoji、description 和 category 字段
        struct RawEmoji: Codable {
            let emoji: String
            let description: String
            let category: String
        }
        let rawList = (try? decoder.decode([RawEmoji].self, from: data)) ?? []
        return rawList.map { EmojiItem(emoji: $0.emoji, description: $0.description, category: $0.category) }
    }
}