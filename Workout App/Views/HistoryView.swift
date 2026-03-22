import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: WorkoutStore

    private static let sessionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        Group {
            if store.sortedSessions.isEmpty {
                ContentUnavailableView(
                    "No workouts yet",
                    systemImage: "dumbbell.fill",
                    description: Text("Log your first session to start building your history.")
                )
            } else {
                List {
                    ForEach(store.sortedSessions) { session in
                        NavigationLink {
                            WorkoutSessionDetailView(session: session)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(session.title)
                                        .font(.headline)
                                    Spacer()
                                    Text(Self.sessionDateFormatter.string(from: session.date))
                                        .foregroundStyle(.secondary)
                                }

                                Text("\(session.exerciseCount) exercises")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 10) {
                                    badge(title: "Volume", value: "\(Int(session.totalVolume)) kg")
                                    badge(title: "Top lift", value: strongestLift(in: session))
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                .modifier(PlatformGroupedListStyle())
            }
        }
        .navigationTitle("History")
    }

    private func badge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(secondaryBackgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func strongestLift(in session: WorkoutSession) -> String {
        guard let exercise = session.exercises.max(by: { $0.bestWeight < $1.bestWeight }) else {
            return "-"
        }

        return "\(exercise.name) \(Int(exercise.bestWeight))"
    }
}

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession

    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: Self.detailDateFormatter.string(from: session.date))
                LabeledContent("Volume", value: "\(Int(session.totalVolume)) kg")
                LabeledContent("Exercises", value: "\(session.exerciseCount)")
                if !session.notes.isEmpty {
                    LabeledContent("Notes") {
                        Text(session.notes)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            ForEach(session.exercises) { exercise in
                Section(exercise.name) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                            Spacer()
                            Text("\(set.weight.formatted(.number.precision(.fractionLength(0...1)))) kg x \(set.reps)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(session.title)
        .modifier(InlineNavigationTitleModifier())
    }
}

private var secondaryBackgroundColor: Color {
    #if os(iOS)
    Color(uiColor: .secondarySystemBackground)
    #else
    Color(nsColor: .windowBackgroundColor)
    #endif
}

struct PlatformGroupedListStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.listStyle(.insetGrouped)
        #else
        content.listStyle(.inset)
        #endif
    }
}

struct InlineNavigationTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.navigationBarTitleDisplayMode(.inline)
        #else
        content
        #endif
    }
}
