import SwiftUI
// Fixture: the colour read from the palette. A hex in a comment, Color(hex: "#000"), and in a string are not code.
struct HexClean: View {
    var body: some View { Text("Color(hex: \"#fff\")").foregroundColor(AppColors.gold) }
}
