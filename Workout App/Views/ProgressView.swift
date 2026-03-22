import Charts
import SwiftUI

struct ProgressDashboardView: View {
    @EnvironmentObject private var store: WorkoutStore
    @State private var selectedExercise = "Back Squat"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if store.exerciseNames.isEmpty {
                    ContentUnavailableView(
                        "No exercise data yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Save workouts to see your progress over time.")
                    )
                } else {
                    Picker("Exercise", selection: $selectedExercise) {
                        ForEach(store.exerciseNames, id: \.self) { exercise in
                            Text(exercise).tag(exercise)
                        }
                    }
                    .pickerStyle(.menu)

                    summaryCard
                    bestWeightChart
                    volumeChart
                }
            }
            .padding(20)
        }
        .background(progressScreenBackground.ignoresSafeArea())
        .navigationTitle("Progress")
        .onAppear {
            if !store.exerciseNames.contains(selectedExercise), let first = store.exerciseNames.first {
                selectedExercise = first
            }
        }
    }

    private var points: [ProgressPoint] {
        store.progressPoints(for: selectedExercise)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedExercise)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("Personal best: \(store.personalBest(for: selectedExercise).formatted(.number.precision(.fractionLength(0...1)))) kg")
                .foregroundStyle(.secondary)
            Text("\(points.count) logged sessions")
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(progressCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var bestWeightChart: some View {
        chartCard(title: "Best weight") {
            if points.isEmpty {
                chartEmptyState
            } else {
                Chart(points) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.bestWeight)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.25), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.bestWeight)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.bestWeight)
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(points.count, 4))) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 220)
            }
        }
    }

    private var volumeChart: some View {
        chartCard(title: "Session volume") {
            if points.isEmpty {
                chartEmptyState
            } else {
                Chart(points) { point in
                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Volume", point.totalVolume)
                    )
                    .foregroundStyle(Color.blue)
                    .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(points.count, 4))) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 220)
            }
        }
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(progressCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var chartEmptyState: some View {
        ContentUnavailableView(
            "No data for this exercise",
            systemImage: "figure.strengthtraining.traditional",
            description: Text("Log this lift in a workout to start graphing it.")
        )
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }
}

private var progressScreenBackground: Color {
    #if os(iOS)
    Color(uiColor: .systemGroupedBackground)
    #else
    Color(nsColor: .windowBackgroundColor)
    #endif
}

private var progressCardBackground: Color {
    #if os(iOS)
    Color(uiColor: .secondarySystemGroupedBackground)
    #else
    Color(nsColor: .controlBackgroundColor)
    #endif
}
