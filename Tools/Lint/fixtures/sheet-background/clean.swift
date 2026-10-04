import SwiftUI
// Fixture: grounds set inline, through sheetGround(), through the presented
// type's own body, and through a view property.
struct SheetBackgroundClean: View {
    @State private var a = false
    @State private var b = false
    @State private var c = false
    @State private var d = false
    var body: some View {
        Text("x")
            .sheet(isPresented: $a) {
                Text("A").presentationBackground(AppColors.background)
            }
            .sheet(isPresented: $b) {
                Text("B").sheetGround()
            }
            .sheet(isPresented: $c) {
                FixtureGroundedSheet()
            }
            .sheet(isPresented: $d) {
                propertySheet
            }
    }
    private var propertySheet: some View {
        Text("D").presentationBackground(AppColors.background)
    }
}

struct FixtureGroundedSheet: View {
    var body: some View { Text("C").sheetGround() }
}

#Preview {
    Color.black.sheet(isPresented: .constant(true)) { Text("A preview is not the app") }
}
