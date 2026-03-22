import Foundation

@MainActor
final class WorkoutStore: ObservableObject {
    @Published private(set) var sessions: [WorkoutSession] = []
    @Published private(set) var customExercises: [String] = []

    private let defaultExerciseLibrary = [
        "Back Squat",
        "Bench Press",
        "Deadlift",
        "Overhead Press",
        "Barbell Row",
        "Pull-Up",
        "Incline Dumbbell Press",
        "Romanian Deadlift",
        "Walking Lunge",
        "Lat Pulldown",
        "Cable Row",
        "Bicep Curl",
        "Tricep Pushdown",
        "Leg Press"
    ]

    private let fileURL: URL
    private let customExercisesURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.fileURL = documentsDirectory.appendingPathComponent("workout-sessions.json")
        self.customExercisesURL = documentsDirectory.appendingPathComponent("custom-exercises.json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        load()
    }

    var sortedSessions: [WorkoutSession] {
        sessions.sorted { $0.date > $1.date }
    }

    var exerciseNames: [String] {
        let savedExerciseNames = Set(sessions.flatMap { $0.exercises.map(\.name) })
        return Array(Set(defaultExerciseLibrary).union(customExercises).union(savedExerciseNames)).sorted()
    }

    func registerExercise(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !exerciseNames.contains(trimmed) else { return }

        customExercises.append(trimmed)
        customExercises.sort()
        persistCustomExercises()
    }

    func addSession(title: String, date: Date, exercises: [LoggedExercise], notes: String) -> Bool {
        let cleanedExercises = exercises
            .map { exercise in
                LoggedExercise(
                    id: exercise.id,
                    name: exercise.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    sets: exercise.sets.filter { $0.reps > 0 && $0.weight >= 0 }
                )
            }
            .filter { !$0.name.isEmpty && !$0.sets.isEmpty }

        guard !cleanedExercises.isEmpty else { return false }

        cleanedExercises.forEach { registerExercise(name: $0.name) }

        let session = WorkoutSession(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty("Workout"),
            date: date,
            exercises: cleanedExercises,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        sessions.append(session)
        persist()
        return true
    }

    func progressPoints(for exerciseName: String) -> [ProgressPoint] {
        sortedSessions
            .reversed()
            .compactMap { session in
                guard let exercise = session.exercises.first(where: { $0.name == exerciseName }) else {
                    return nil
                }

                return ProgressPoint(
                    date: session.date,
                    exerciseName: exercise.name,
                    bestWeight: exercise.bestWeight,
                    totalVolume: exercise.totalVolume
                )
            }
    }

    func personalBest(for exerciseName: String) -> Double {
        progressPoints(for: exerciseName).map(\.bestWeight).max() ?? 0
    }

    func totalVolumeLast30Days() -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return sessions
            .filter { $0.date >= cutoff }
            .reduce(0) { $0 + $1.totalVolume }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([WorkoutSession].self, from: data) else {
            sessions = []
            loadCustomExercises()
            return
        }

        sessions = decoded
        loadCustomExercises()
    }

    private func persist() {
        guard let data = try? encoder.encode(sessions) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }

    private func loadCustomExercises() {
        guard let data = try? Data(contentsOf: customExercisesURL),
              let decoded = try? decoder.decode([String].self, from: data) else {
            customExercises = []
            return
        }

        customExercises = decoded.sorted()
    }

    private func persistCustomExercises() {
        guard let data = try? encoder.encode(customExercises) else { return }
        try? data.write(to: customExercisesURL, options: [.atomic])
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
