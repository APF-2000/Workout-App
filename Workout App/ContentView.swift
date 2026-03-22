import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LogWorkoutView()
            }
            .tabItem {
                Label("Log", systemImage: "plus.circle.fill")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }

            NavigationStack {
                ProgressDashboardView()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.xyaxis.line")
            }
        }
        .tint(Color(red: 0.77, green: 0.24, blue: 0.18))
    }
}
