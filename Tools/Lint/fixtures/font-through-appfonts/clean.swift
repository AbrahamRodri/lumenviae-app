import SwiftUI
import UIKit
// Fixture: the face through AppFonts, and a measurement with a name read from it.
struct FontClean: View {
    var body: some View { Text("x").font(AppFonts.titleFont(17)) }
    func measure(name: String) -> UIFont? { UIFont(name: name, size: 17) }
}
