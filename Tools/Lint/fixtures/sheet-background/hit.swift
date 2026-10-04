import SwiftUI
// Fixture: a sheet whose content never sets its ground.
struct SheetBackgroundHit: View {
    @State private var shown = false
    var body: some View {
        Text("x").sheet(isPresented: $shown) {
            Text("Inside")
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }
}
