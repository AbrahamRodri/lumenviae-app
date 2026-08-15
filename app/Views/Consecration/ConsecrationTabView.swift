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
//  - Active consecration → Auto-load today's day overview
//

import SwiftUI
import SwiftData

// MARK: - ConsecrationRoute

/// Navigation routes within the Consecration tab
/// A step within a day: the reading, then each of its prayers. The
/// dashboard can open any of them, and the flow itself moves between
/// them — so the reading is the first step of the same screen rather
/// than a cover that has to dismiss before the prayers can be pushed.
enum ConsecrationDayStep: Hashable {
    case reading
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

    /// Callback to notify parent when navigation depth changes (for hiding tab bar)
    var onNavigationChange: ((Bool) -> Void)?

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
        .onChange(of: path.count) { _, newCount in
            onNavigationChange?(newCount > 0)
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

    @ViewBuilder
    private var rootView: some View {
        if viewModel.hasActiveConsecration {
            ConsecrationDayOverviewView(path: $path)
        } else {
            ConsecrationOnboardingView(path: $path)
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
