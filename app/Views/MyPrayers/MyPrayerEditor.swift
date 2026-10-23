//
//  MyPrayerEditor.swift
//  Lumen Viae
//
//  A prayer of the reader's own, written or changed: its name, its
//  words and the image it hangs. The words are kept as typed, a
//  paragraph a line, and prayed as the book's prose is.
//

import SwiftUI

struct MyPrayerEditor: View {

    /// The prayer being changed, or nil for a new one
    let existing: CustomPrayer?

    /// Told of the prayer once saved, so a playlist editor that opened
    /// this can add it
    var onSave: ((CustomPrayer) -> Void)?

    @Environment(\.dismiss) private var dismiss

    private let store = MyPrayersStore.shared

    @State private var title = ""
    @State private var text = ""
    @State private var art: String?
    @State private var choosingArt = false
    @State private var confirmingDelete = false

    @FocusState private var titleFocused: Bool
    @FocusState private var textFocused: Bool

    init(existing: CustomPrayer? = nil, onSave: ((CustomPrayer) -> Void)? = nil) {
        self.existing = existing
        self.onSave = onSave
    }

    private var hasNoText: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                SheetHeader(kicker: "My Prayers", title: existing == nil ? "New Prayer" : "Edit Prayer") {
                    HStack(spacing: 4) {
                        SheetHeaderAction(title: "Cancel") { dismiss() }
                        SheetHeaderAction(title: "Save", action: save)
                            .disabled(hasNoText)
                            .opacity(hasNoText ? 0.35 : 1)
                    }
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Name")
                            TextField("Morning Offering", text: $title)
                                .font(AppFonts.readingFont(20))
                                .foregroundColor(AppColors.cream)
                                .tint(AppColors.gold)
                                .focused($titleFocused)
                                .submitLabel(.next)
                                .onSubmit { textFocused = true }
                                .padding(.bottom, 4)
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(AppColors.gold.opacity(titleFocused ? 0.75 : 0.3))
                                        .frame(height: titleFocused ? 1.5 : 1)
                                }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Words")
                            ZStack(alignment: .topLeading) {
                                if text.isEmpty {
                                    Text("Write the prayer as you say it…")
                                        .font(AppFonts.readingItalicFont(18))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                                TextEditor(text: $text)
                                    .font(AppFonts.readingFont(18))
                                    .foregroundColor(AppColors.cream)
                                    .tint(AppColors.gold)
                                    .scrollContentBackground(.hidden)
                                    .focused($textFocused)
                                    .lineSpacing(5)
                                    .frame(minHeight: 240)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.cardBackground))
                        }

                        MyPrayersArtRow(art: art, fallback: .saved) { choosingArt = true }

                        if existing != nil {
                            Button(role: .destructive) {
                                confirmingDelete = true
                            } label: {
                                Text("DELETE THIS PRAYER")
                                    .font(AppFonts.labelFont(9.5))
                                    .tracking(2)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(QuietGlyphButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            if let existing {
                title = existing.title
                text = existing.text
                art = existing.art
            } else {
                titleFocused = true
            }
        }
        .sheet(isPresented: $choosingArt) {
            MyPrayersArtPicker(current: art) { art = $0 }
                .myPrayersSheet()
        }
        .confirmationDialog("Delete this prayer?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let existing { store.delete(existing) }
                dismiss()
            }
        } message: {
            Text("It is taken out of every playlist it is in.")
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        MyPrayersLabel(title)
    }

    private func save() {
        var prayer = existing ?? CustomPrayer(title: "", text: "")
        prayer.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        prayer.text = text
        prayer.art = art
        store.save(prayer)
        onSave?(prayer)
        dismiss()
    }
}
