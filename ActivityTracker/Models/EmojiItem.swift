import Foundation

struct EmojiItem: Codable, Identifiable {
    var id: String { emoji } // 用 emoji 本身做唯一 id
    let emoji: String
    let description: String
    let category: String // 新增分类字段
}