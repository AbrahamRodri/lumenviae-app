import SwiftUI
// Fixture: a page that hides the system bar.
struct BarHit: View {
    var body: some View { Text("x").navigationBarHidden(true) }
}
