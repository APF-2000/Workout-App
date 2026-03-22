import SwiftUI
#if os(iOS)
import UIKit
#endif

struct LogWorkoutView: View {
    @EnvironmentObject private var store: WorkoutStore

    @State private var workoutTitle = ""
    @State private var workoutDate = Date()
    @State private var notes = ""
    @State private var draftExercises: [ExerciseDraft] = [ExerciseDraft()]
    @State private var selectedLibraryExercise = "Back Squat"
    @State private var customExerciseName = ""
    @State private var showingSavedBanner = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                workoutDetailsCard
                exercisePickerCard

                ForEach($draftExercises) { $exercise in
                    ExerciseDraftCard(exercise: $exercise, onRemove: {
                        removeDraft(id: exercise.id)
                    })
                }
            }
            .padding(20)
        }
        .background(screenBackground.ignoresSafeArea())
        .navigationTitle("Log Workout")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    saveWorkout()
                }
                .fontWeight(.semibold)
            }
        }
        .overlay(alignment: .top) {
            if showingSavedBanner {
                Text("Workout saved")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showingSavedBanner)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Strength log")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("Track sets, weights, and reps with zero account setup. Everything stays on your phone.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                statPill(title: "Sessions", value: "\(store.sessions.count)")
                statPill(title: "30-day volume", value: "\(Int(store.totalVolumeLast30Days())) kg")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.accentColor)
        )
        .foregroundStyle(.white)
    }

    private var workoutDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Workout details")
                .font(.headline)
                .foregroundStyle(.primary)

            TextField("Push day, Legs, Full body...", text: $workoutTitle)
                .modifier(WorkoutInputFieldModifier())

            DatePicker("Date", selection: $workoutDate, displayedComponents: [.date])
                .foregroundStyle(.primary)

            TextField("Notes", text: $notes, axis: .vertical)
                .modifier(WorkoutInputFieldModifier())
                .lineLimit(2...4)
        }
        .padding(18)
        .foregroundStyle(.primary)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var exercisePickerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add exercise")
                .font(.headline)
                .foregroundStyle(.primary)

            Picker("Exercise", selection: $selectedLibraryExercise) {
                ForEach(store.exerciseNames, id: \.self) { exercise in
                    Text(exercise).tag(exercise)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Button("Add from library") {
                    draftExercises.append(ExerciseDraft(name: selectedLibraryExercise))
                }
                .buttonStyle(FilledWorkoutButton())

                Button("Quick blank") {
                    draftExercises.append(ExerciseDraft())
                }
                .buttonStyle(OutlineWorkoutButton())
            }

            HStack {
                TextField("Custom exercise name", text: $customExerciseName)
                    .modifier(WorkoutInputFieldModifier())

                Button("Add") {
                    let trimmed = customExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.registerExercise(name: trimmed)
                    selectedLibraryExercise = trimmed
                    draftExercises.append(ExerciseDraft(name: trimmed))
                    customExerciseName = ""
                }
                .buttonStyle(FilledWorkoutButton())
            }
        }
        .padding(18)
        .foregroundStyle(.primary)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
            Text(value)
                .font(.title3.weight(.bold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func removeDraft(id: UUID) {
        guard draftExercises.count > 1 else { return }
        draftExercises.removeAll { $0.id == id }
    }

    private func saveWorkout() {
        let exercises = draftExercises.map { draft in
            LoggedExercise(
                id: draft.id,
                name: draft.name,
                sets: draft.sets.map { ExerciseSet(id: $0.id, weight: $0.weight, reps: $0.reps) }
            )
        }

        let didSave = store.addSession(
            title: workoutTitle,
            date: workoutDate,
            exercises: exercises,
            notes: notes
        )

        guard didSave else { return }

        workoutTitle = ""
        workoutDate = Date()
        notes = ""
        draftExercises = [ExerciseDraft()]
        showingSavedBanner = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showingSavedBanner = false
        }
    }
}

struct ExerciseDraftCard: View {
    @Binding var exercise: ExerciseDraft
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                TextField("Exercise name", text: $exercise.name)
                    .font(.headline)
                    .modifier(WorkoutInputFieldModifier())

                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                }
            }

            ForEach($exercise.sets) { $set in
                HStack(spacing: 12) {
                    Text("Set")
                        .frame(width: 36, alignment: .leading)
                        .foregroundStyle(.secondary)

                    TextField("kg", value: $set.weight, format: .number)
                        .modifier(IOSKeyboardTypeModifier(kind: .decimalPad))
                        .modifier(WorkoutInputFieldModifier())

                    TextField("reps", value: $set.reps, format: .number)
                        .modifier(IOSKeyboardTypeModifier(kind: .numberPad))
                        .modifier(WorkoutInputFieldModifier())

                    Button(role: .destructive) {
                        guard exercise.sets.count > 1 else { return }
                        exercise.sets.removeAll { $0.id == set.id }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                }
            }

            Button {
                exercise.sets.append(SetDraft())
            } label: {
                Label("Add set", systemImage: "plus")
            }
            .buttonStyle(OutlineWorkoutButton())
        }
        .padding(18)
        .foregroundStyle(.primary)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct ExerciseDraft: Identifiable {
    var id = UUID()
    var name: String = ""
    var sets: [SetDraft] = [SetDraft()]
}

struct SetDraft: Identifiable {
    var id = UUID()
    var weight: Double = 0
    var reps: Int = 0
}

struct FilledWorkoutButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.77, green: 0.24, blue: 0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct OutlineWorkoutButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 0.77, green: 0.24, blue: 0.18), lineWidth: 1.5)
                    .background(Color.clear)
            )
            .foregroundStyle(Color(red: 0.50, green: 0.19, blue: 0.15))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct IOSKeyboardTypeModifier: ViewModifier {
    enum Kind {
        case decimalPad
        case numberPad
    }

    let kind: Kind

    func body(content: Content) -> some View {
        #if os(iOS)
        content.keyboardType(kind == .decimalPad ? .decimalPad : .numberPad)
        #else
        content
        #endif
    }
}

struct WorkoutInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(inputBorder, lineWidth: 1)
            )
            .foregroundStyle(.primary)
    }
}

private var screenBackground: Color {
    #if os(iOS)
    Color(uiColor: .systemGroupedBackground)
    #else
    Color(nsColor: .windowBackgroundColor)
    #endif
}

private var cardBackground: Color {
    #if os(iOS)
    Color(uiColor: .secondarySystemGroupedBackground)
    #else
    Color(nsColor: .controlBackgroundColor)
    #endif
}

private var inputBackground: Color {
    #if os(iOS)
    Color(uiColor: .systemBackground)
    #else
    Color(nsColor: .textBackgroundColor)
    #endif
}

private var inputBorder: Color {
    #if os(iOS)
    Color(uiColor: .separator).opacity(0.35)
    #else
    Color.gray.opacity(0.25)
    #endif
}
