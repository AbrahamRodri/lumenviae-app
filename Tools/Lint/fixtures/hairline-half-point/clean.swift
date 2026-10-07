import SwiftUI
// Fixture: the hairline token, and 0.55 / 1.5, which are other numbers.
struct HairlineClean: View {
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold, lineWidth: AppLine.hairline)
            Rectangle().frame(height: 1.5).opacity(0.5)
            Circle().stroke(lineWidth: 0.55)
        }
    }
}
