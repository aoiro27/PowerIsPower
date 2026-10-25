import SwiftUI

enum Palette {
    static let accent = Color(red: 0.77, green: 0.96, blue: 0.35)
    static let background = Color(red: 0.055, green: 0.065, blue: 0.065)
    static let card = Color(red: 0.105, green: 0.12, blue: 0.115)
}

struct ExerciseRow: View {
    let exercise: Exercise
    var showIncrement = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.name)
                .font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(exercise.weight.weightText)
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text(exercise.unit.label).foregroundStyle(.secondary)
                Text("×").foregroundStyle(.secondary).padding(.horizontal, 6)
                Text("\(exercise.reps)")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                Text("回").foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            Text("≈ \(exercise.unit.convertedText(exercise.weight))")
                .font(.subheadline).foregroundStyle(.secondary)
            if showIncrement {
                Label("次回 +\(exercise.unit.dualText(exercise.increment))", systemImage: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

struct PrimaryButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .foregroundStyle(.black)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
