import Foundation

struct ExerciseSet: Identifiable, Codable, Hashable {
    var id = UUID()
    var weight: Double
    var reps: Int

    var volume: Double {
        weight * Double(reps)
    }
}

struct LoggedExercise: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var sets: [ExerciseSet]

    var bestWeight: Double {
        sets.map(\.weight).max() ?? 0
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }
}

struct WorkoutSession: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var date: Date
    var exercises: [LoggedExercise]
    var notes: String

    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.totalVolume }
    }

    var exerciseCount: Int {
        exercises.count
    }
}

struct ProgressPoint: Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var exerciseName: String
    var bestWeight: Double
    var totalVolume: Double
}
