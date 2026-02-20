//
//  ConsecrationTabView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION TAB VIEW - ROOT VIEW FOR 33-DAY CONSECRATION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  The main container view for the 33-Day Total Consecration feature.
//  Handles navigation within the consecration flow and determines which
//  view to show based on the user's progress state.
//
//  ## Behavior
//  - No active consecration → Show intro/start view
//  - Active consecration → Auto-load today's day overview
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI
import SwiftData

// MARK: - ConsecrationRoute

/// Navigation routes within the Consecration tab
enum ConsecrationRoute: Hashable {
    case dayOverview(dayNumber: Int)
    case prayerFlow(dayNumber: Int)
    case meditation(dayNumber: Int)
    case journal(dayNumber: Int)
    case completion
}

// MARK: - ConsecrationTabView

struct ConsecrationTabView: View {

    // MARK: - Properties

    @State private var viewModel = ConsecrationViewModel()
    @State private var path = NavigationPath()

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
    }

    // MARK: - Root View

    @ViewBuilder
    private var rootView: some View {
        if viewModel.hasActiveConsecration {
            ConsecrationDayOverviewView(path: $path)
        } else {
            ConsecrationIntroView(path: $path)
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for route: ConsecrationRoute) -> some View {
        switch route {
        case .dayOverview(let dayNumber):
            ConsecrationDayOverviewView(path: $path, dayNumber: dayNumber)

        case .prayerFlow(let dayNumber):
            ConsecrationPrayerFlowView(path: $path, dayNumber: dayNumber)

        case .meditation(let dayNumber):
            ConsecrationMeditationView(path: $path, dayNumber: dayNumber)

        case .journal(let dayNumber):
            ConsecrationJournalView(path: $path, dayNumber: dayNumber)

        case .completion:
            ConsecrationCompletionView(path: $path)
        }
    }
}

// MARK: - Preview

#Preview {
    ConsecrationTabView()
        .modelContainer(for: [ConsecrationProgress.self, JournalEntry.self])
}
