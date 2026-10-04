import SwiftUI
// Fixture: the cap set on the content, inline and in the presented type.
struct SheetTypeCapClean: View {
    @State private var a = false
    @State private var b = false
    var body: some View {
        Text("x")
            .fullScreenCover(isPresented: $a) {
                Text("A").dynamicTypeSize(...DynamicTypeSize.appMaximum)
            }
            .sheet(isPresented: $b) {
                FixtureCappedSheet()
            }
    }
}

struct FixtureCappedSheet: View {
    var body: some View { Text("B").dynamicTypeSize(...DynamicTypeSize.appMaximum) }
}
