//
//  ConsecrationTabView.swift
//  Lumen Viae
//
//  The main container view for the 33-Day Total Consecration feature.
//  Handles navigation within the consecration flow and determines which
//  view to show based on the user's progress state.
//
//  ## Behavior
//  - No active consecration → Show intro/start view
//  - A consecration chosen ahead, before its Day 1 → its scheduled page
//  - Active consecration → Auto-load today's day overview
//

import SwiftUI
import SwiftData

// MARK: - ConsecrationRoute

/// Navigation routes within the Consecration tab
/// A step within a day: each of its prayers, then each of its readings.
/// The dashboard can open any of them, and the flow itself moves between
/// them — so the reading is a step of the same screen rather than a
/// cover that has to dismiss before the prayers can be pushed.
///
/// `reading` carries an index because most days have two: a Gospel
/// passage and a spiritual reading. They are separate texts from
/// separate works, so they are separate steps rather than one scroll
/// with a rule buried somewhere down it.
enum ConsecrationDayStep: Hashable {
    case reading(Int)
    case prayer(Int)
}

enum ConsecrationRoute: Hashable {
    case dayOverview(dayNumber: Int)
    /// The day's reading and prayers as one flow, opened at any step.
    case dayFlow(dayNumber: Int, step: ConsecrationDayStep)
    case journal(dayNumber: Int)
    case completion
    case trueDevotionReader
}

// MARK: - ConsecrationTabView

struct ConsecrationTabView: View {

    // MARK: - Properties

    @State private var viewModel = ConsecrationViewModel()

    /// A typed stack rather than a `NavigationPath`. Every destination in
    /// this tab is a `ConsecrationRoute`, and the journey grid needs to
    /// read the top of the stack so that opening another day *replaces*
    /// the day being read instead of piling identical screens on it.
    @State private var path: [ConsecrationRoute] = []

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    /// The introduction asks for the tab bar to step aside while it is
    /// walked (see `ConsecrationOnboardingView.hidesTabBar`)
    @State private var introHidesTabBar = false

    /// Today, as the root reads it: a consecration chosen ahead waits on
    /// its own page until Day 1, and turns into Day 1 at midnight, or on
    /// coming back to the app after it, without leaving the tab
    @State private var today = Date()

    /// Callback to notify parent when the tab bar should hide: a page
    /// pushed, or the introduction being walked
    var onNavigationChange: ((Bool) -> Void)?

    private var hidesTabBar: Bool {
        !path.isEmpty || (introHidesTabBar && viewModel.progress == nil)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $path) {
            rootView
                .navigationDestination(for: ConsecrationRoute.self) { route in
                    destinationView(for: route)
                        .environment(viewModel)
                }
        }
        .environment(viewModel)
        .onAppear {
            viewModel.setModelContext(modelContext)
            viewModel.loadProgress()
        }
        .onChange(of: hidesTabBar) { _, hides in
            onNavigationChange?(hides)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today = Date() }
        }
        // Sleeps to the next midnight while a start is waiting, then
        // reads the day again. Keyed on the start too, so a feast chosen
        // while the tab is open sets the watch going.
        .task(id: [today, scheduledStart ?? .distantPast]) {
            guard let start = scheduledStart else { return }
            let calendar = Calendar.current
            guard let midnight = calendar.date(
                byAdding: .day, value: 1, to: calendar.startOfDay(for: today)
            ) else { return }
            let wait = max(1, midnight.timeIntervalSince(Date()) + 1)
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            today = Date()
            if calendar.startOfDay(for: start) <= calendar.startOfDay(for: today) {
                viewModel.loadCurrentDay()
            }
        }
        // Surface persistence failures anywhere in the flow — a day that
        // fails to save should never fail silently.
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Root View

    /// Day 1 of a consecration chosen ahead whose first day has not come
    private var scheduledStart: Date? {
        guard let progress = viewModel.progress,
              !progress.isCompleted,
              !progress.hasBegun(asOf: today) else { return nil }
        return progress.startDate
    }

    @ViewBuilder
    private var rootView: some View {
        if let start = scheduledStart {
            ConsecrationScheduledView(start: start, path: $path)
        } else if viewModel.hasActiveConsecration {
            ConsecrationDayOverviewView(path: $path)
        } else {
            ConsecrationOnboardingView(path: $path, hidesTabBar: $introHidesTabBar)
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for route: ConsecrationRoute) -> some View {
        switch route {
        case .dayOverview(let dayNumber):
            ConsecrationDayOverviewView(path: $path, dayNumber: dayNumber)

        case .dayFlow(let dayNumber, let step):
            ConsecrationDayFlowView(path: $path, dayNumber: dayNumber, startStep: step)

        case .journal(let dayNumber):
            ConsecrationJournalView(path: $path, dayNumber: dayNumber)

        case .completion:
            ConsecrationCompletionView(path: $path)

        case .trueDevotionReader:
            TrueDevotionReaderView()
        }
    }
}

// MARK: - Preview

#Preview {
    ConsecrationTabView()
        .modelContainer(for: [ConsecrationProgress.self, JournalEntry.self])
}
