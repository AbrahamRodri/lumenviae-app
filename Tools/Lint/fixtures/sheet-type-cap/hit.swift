import SwiftUI
// Fixture: a cover that takes the phone's text size uncapped.
struct SheetTypeCapHit: View {
    @State private var shown = false
    var body: some View {
        Text("x").fullScreenCover(isPresented: $shown) {
            Text("Inside").presentationBackground(AppColors.background)
        }
    }
}
