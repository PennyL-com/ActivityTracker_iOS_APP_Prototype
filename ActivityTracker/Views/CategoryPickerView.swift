import SwiftUI
import CoreData

// 可复用的分类选择器
struct CategoryPickerView: View {
    @Binding var selection: String
    let categories = ["Hobby", "Health", "Pet", "Home", "Others", "Education"].sorted()
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(categories, id: \.self) { cat in
                Text(cat)
            }
        }
    }
}