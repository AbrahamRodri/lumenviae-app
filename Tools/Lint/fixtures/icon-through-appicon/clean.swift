import SwiftUI
// Fixture: the icon through AppIcon; a painting loaded by name is not an icon.
struct IconClean: View {
    var body: some View {
        VStack {
            AppIcon.image("ph-caret-right")
            Image("annunciation")
        }
    }
}
