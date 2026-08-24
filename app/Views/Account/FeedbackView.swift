//
//  FeedbackView.swift
//  Lumen Viae
//
//  Feedback written inside the app, on the app's own paper.
//
//  What this replaces: a bare `mailto:` that threw you out to Mail with
//  an empty message and a subject line you had to make sense of. People
//  wrote nothing, or wrote it somewhere else. So the writing happens
//  here — you say what kind of note it is, you write it in a field that
//  looks like the rest of the app, and the version, device, and the
//  meditation you were on are gathered for you rather than asked for.
//
//  Mail is still the wire it travels on. `MFMailComposeViewController`
//  is a mail sheet *inside* the app: it opens already addressed, already
//  filled, from the sender's own account — so a reply reaches them with
//  nothing else to set up, and nothing about the note ever touches our
//  server. It is the app's one UIKit view, and it is here for that
//  reason; the fallbacks below cover the phones that cannot show it.
//

import SwiftUI
import MessageUI
import UIKit

// MARK: - Topic

/// What kind of note this is. Sets the subject line so a mailbox full of
/// these sorts itself.
enum FeedbackTopic: String, CaseIterable, Identifiable {

    case problem
    case idea
    case meditations
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .problem: return "Something's wrong"
        case .idea: return "An idea"
        case .meditations: return "The meditations"
        case .other: return "Something else"
        }
    }

    var icon: String {
        switch self {
        case .problem: return "ph-wrench"
        case .idea: return "ph-sparkle"
        case .meditations: return "ph-book-open"
        case .other: return "ph-chat-teardrop-text"
        }
    }

    /// Leads the subject line, so the inbox groups by kind.
    var subjectPrefix: String {
        switch self {
        case .problem: return "Issue"
        case .idea: return "Idea"
        case .meditations: return "Meditations"
        case .other: return "Feedback"
        }
    }

    /// What the empty field asks for. A blank sheet gets blank answers;
    /// the prompt changes with the topic so it asks the right question.
    var prompt: String {
        switch self {
        case .problem: return "What happened, and what were you doing when it did?"
        case .idea: return "What would you like Lumen Viae to do?"
        case .meditations: return "What did you notice — a typo, a translation, a passage?"
        case .other: return "Say anything you'd like us to hear…"
        }
    }
}

// MARK: - Context

/// Where the note was written from. The prayer tray fills this in so a
/// report about a meditation names the meditation without anyone having
/// to describe which one it was.
struct FeedbackContext: Equatable {

    /// The meditation on screen, e.g. "The Annunciation"
    let meditationTitle: String

    /// The set it belongs to
    let setName: String

    /// Shown in the form, and carried into the message.
    var summary: String { "\(meditationTitle) — \(setName)" }
}

// MARK: - Draft

/// The note as it will be sent. Kept apart from the view so the subject
/// and body are one definition, whether they leave by the mail sheet, a
/// `mailto:`, or the clipboard.
struct FeedbackDraft {

    let topic: FeedbackTopic
    let message: String
    let context: FeedbackContext?

    var subject: String {
        if let context {
            return "Lumen Viae \(topic.subjectPrefix): \(context.meditationTitle)"
        }
        return "Lumen Viae \(topic.subjectPrefix)"
    }

    /// The message first, then a signature block of everything needed to
    /// reproduce what was reported. Below a rule, so it never reads as
    /// part of what the person wrote.
    var body: String {
        var lines = [message.trimmingCharacters(in: .whitespacesAndNewlines), "", "—"]

        if let context {
            lines.append("Meditation: \(context.summary)")
        }

        lines.append("About: \(topic.title)")
        lines.append(
            "Lumen Viae \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))"
        )
        lines.append("\(Self.deviceModel) · iOS \(UIDevice.current.systemVersion)")

        return lines.joined(separator: "\n")
    }

    /// The hardware identifier ("iPhone16,2") rather than `UIDevice`'s
    /// flat "iPhone", which cannot tell a Pro Max from an SE.
    ///
    /// Under a simulator `uname` answers for the Mac ("arm64"), which
    /// says nothing about the device being simulated — so the simulated
    /// identifier is preferred there, marked as such.
    static let deviceModel: String = {
        let environment = ProcessInfo.processInfo.environment
        if let simulated = environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return "\(simulated) (Simulator)"
        }

        var system = utsname()
        uname(&system)
        let identifier = withUnsafeBytes(of: &system.machine) { raw in
            raw.prefix { $0 != 0 }.map { UInt8($0) }
        }
        let name = String(decoding: identifier, as: UTF8.self)
        return name.isEmpty ? UIDevice.current.model : name
    }()

    /// The same note as a `mailto:`, for phones with no Mail account set
    /// up. Nil only if the text cannot be escaped.
    var mailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Constants.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}

// MARK: - Feedback View

struct FeedbackView: View {

    /// Filled by the prayer tray; nil when opened from Account.
    var context: FeedbackContext?

    /// The topic the sheet opens on. The prayer tray starts on the
    /// meditations, since that is what you were looking at.
    var initialTopic: FeedbackTopic = .other

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var topic: FeedbackTopic = .other
    @State private var message: String = ""
    @State private var stage: Stage = .writing
    @State private var showMailSheet = false
    @State private var didSeed = false

    @FocusState private var messageFocused: Bool

    /// Writing, then thanked. The sheet does not simply vanish on send —
    /// a note that disappears leaves you unsure it went.
    private enum Stage {
        case writing
        case sent
        /// No Mail account, and the `mailto:` handoff found no taker
        case noMailApp
    }

    private var draft: FeedbackDraft {
        FeedbackDraft(topic: topic, message: message, context: context)
    }

    private var canSend: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            switch stage {
            case .writing:
                form
            case .sent:
                thanks
            case .noMailApp:
                noMail
            }
        }
        .animation(.easeInOut(duration: 0.25), value: stage)
        .onAppear {
            // Guard the seed: this sheet's body can be built more than
            // once, and a second pass must not reset a topic the writer
            // has already changed.
            guard !didSeed else { return }
            didSeed = true
            topic = initialTopic
        }
        .sheet(isPresented: $showMailSheet) {
            MailComposeSheet(draft: draft) { result in
                showMailSheet = false
                switch result {
                case .sent:
                    stage = .sent
                case .cancelled, .saved, .failed:
                    // Back to the form with the text intact — a
                    // cancelled composer must not eat what was written
                    break
                @unknown default:
                    break
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Form

    private var form: some View {
        VStack(spacing: 0) {
            header

            Divider().background(AppColors.gold.opacity(0.2))

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    if let context {
                        contextCard(context)
                    }

                    topicPicker

                    messageField
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) { sendBar }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Text("Cancel")
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text("FEEDBACK")
                .font(AppFonts.bodyFont(11))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            Spacer()

            // Balances the kicker against Cancel, so the title sits
            // centered rather than shouldered to one side
            Text("Cancel")
                .font(AppFonts.bodyFont(16))
                .hidden()
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    /// What you were praying when you opened this, stated rather than
    /// asked for.
    private func contextCard(_ context: FeedbackContext) -> some View {
        HStack(spacing: 10) {
            AppIcon("ph-book-open", size: 14)
                .foregroundColor(AppColors.gold.opacity(0.8))

            VStack(alignment: .leading, spacing: 2) {
                Text(context.meditationTitle)
                    .font(AppFonts.italicFont(16))
                    .foregroundColor(AppColors.cream)

                Text(context.setName)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("About \(context.summary)")
    }

    private var topicPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("What is this about?")

            // Two columns rather than a scrolling row: four choices
            // should all be in view, none of them hiding off an edge.
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    topicChip(.problem)
                    topicChip(.idea)
                }
                GridRow {
                    topicChip(.meditations)
                    topicChip(.other)
                }
            }
        }
    }

    private func topicChip(_ value: FeedbackTopic) -> some View {
        let isSelected = topic == value

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { topic = value }
        } label: {
            HStack(spacing: 8) {
                AppIcon(value.icon, size: 15)

                Text(value.title)
                    .font(AppFonts.bodyFont(14))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .foregroundColor(isSelected ? AppColors.goldLight : AppColors.textSecondary)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppColors.cardElevated : AppColors.cardBackground.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? AppColors.gold.opacity(0.7) : AppColors.gold.opacity(0.18),
                        lineWidth: 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var messageField: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Your note")

            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text(topic.prompt)
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $message)
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)
                    .tint(AppColors.gold)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .lineSpacing(5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .focused($messageFocused)
            }
            // Takes its height from the sheet rather than a constant, so
            // the field fills a Pro Max instead of floating over 300pt
            // of empty card, and still leaves room to write on an SE.
            .containerRelativeFrame(.vertical) { height, _ in
                max(190, height * 0.42)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                AppColors.gold.opacity(messageFocused ? 0.5 : 0.18),
                                lineWidth: 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: messageFocused)

            // Say plainly what rides along. Nothing here is collected
            // quietly, and nothing reaches our server — the note is an
            // email you send yourself.
            Text("Your app version and device are added at the bottom so we can find the problem. Sent as an email from your own account, straight to \(Constants.supportEmail) — nothing goes to our server.")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary.opacity(0.7))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The screen's one gold act, riding above the keyboard.
    private var sendBar: some View {
        VStack(spacing: 0) {
            Divider().background(AppColors.gold.opacity(0.12))

            GoldCTAButton(title: "Send", showsCross: false, trailingIcon: nil) {
                send()
            }
            .disabled(!canSend)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(AppColors.backgroundDeep)
    }

    // MARK: - Sent

    private var thanks: some View {
        VStack(spacing: 20) {
            Spacer()

            AppIcon("ph-check-circle", size: 44)
                .foregroundColor(AppColors.gold)

            Text("Thank you")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)

            Text("Your note is on its way. Every one of them is read.")
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()

            GoldCTAButton(title: "Done", showsCross: false) { dismiss() }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - No Mail

    /// No Mail account, and no app claimed the `mailto:` either. Rather
    /// than lose what was written, hand it to the clipboard whole.
    private var noMail: some View {
        VStack(spacing: 20) {
            Spacer()

            AppIcon("ph-info", size: 40)
                .foregroundColor(AppColors.gold)

            Text("No mail account")
                .font(AppFonts.headlineFont(24))
                .foregroundColor(AppColors.cream)

            Text("This iPhone has no mail account set up, so we couldn't open a message. Your note has been copied — paste it into whichever mail app you use, addressed to \(Constants.supportEmail).")
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Spacer()

            GoldCTAButton(title: "Done", showsCross: false) { dismiss() }
                .padding(.horizontal, 20)

            QuietGoldButton(title: "Back to my note") { stage = .writing }
                .padding(.bottom, 16)
        }
    }

    // MARK: - Send

    private func send() {
        guard canSend else { return }
        messageFocused = false

        if MFMailComposeViewController.canSendMail() {
            showMailSheet = true
            return
        }

        // No Mail account. Some people use Gmail or Outlook alone, which
        // still answer `mailto:` — try that before giving up.
        guard let url = draft.mailtoURL else {
            copyAndExplain()
            return
        }

        openURL(url) { accepted in
            if accepted {
                // Handed off. The note now lives in the other app, so
                // this sheet's work is done.
                stage = .sent
            } else {
                copyAndExplain()
            }
        }
    }

    private func copyAndExplain() {
        UIPasteboard.general.string = "\(draft.subject)\n\n\(draft.body)"
        stage = .noMailApp
    }
}

// MARK: - Section Label

/// The small gold rubric over each part of the form.
private struct SectionLabel: View {

    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased())
            .font(AppFonts.labelFont(10))
            .tracking(2)
            .foregroundColor(AppColors.gold.opacity(0.75))
    }
}

// MARK: - Mail Compose Sheet

/// The system mail composer, opened already addressed and filled.
///
/// The app's only UIKit view. There is no SwiftUI mail composer, and the
/// alternative — throwing the writer out to Mail with a `mailto:` — is
/// exactly what this screen exists to replace.
private struct MailComposeSheet: UIViewControllerRepresentable {

    let draft: FeedbackDraft

    /// Called with what the composer did. Presentation is the caller's:
    /// this view only reports.
    let onFinish: (MFMailComposeResult) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([Constants.supportEmail])
        controller.setSubject(draft.subject)
        controller.setMessageBody(draft.body, isHTML: false)
        return controller
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {
        // The composer owns its own state once presented. Rebuilding its
        // fields under the writer's cursor would undo their edits.
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        private let onFinish: (MFMailComposeResult) -> Void

        init(onFinish: @escaping (MFMailComposeResult) -> Void) {
            self.onFinish = onFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            // A failure to send is not a lost note — the composer keeps
            // it, and the form behind still holds the text.
            onFinish(error == nil ? result : .failed)
        }
    }
}

// MARK: - Preview

#Preview("From Account") {
    Color.black.sheet(isPresented: .constant(true)) {
        FeedbackView()
    }
}

#Preview("From a meditation") {
    Color.black.sheet(isPresented: .constant(true)) {
        FeedbackView(
            context: FeedbackContext(
                meditationTitle: "The Annunciation",
                setName: "Meditations of St. Alphonsus"
            ),
            initialTopic: .meditations
        )
    }
}
