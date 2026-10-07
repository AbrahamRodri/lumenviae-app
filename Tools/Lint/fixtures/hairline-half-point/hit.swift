import SwiftUI
// Fixture: a border and a rule drawn at half a point.
struct HairlineHit: View {
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold, lineWidth: 0.5)
            Rectangle().frame(height: 0.5)
        }
    }
}
