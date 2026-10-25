import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: TrainingStore

    var body: some View {
        NavigationStack {
            Group {
                if store.state.records.isEmpty {
                    ContentUnavailableView("積み重ねを、ここに。", systemImage: "clock.arrow.circlepath",
                                           description: Text("トレーニングを完了すると、\nその日の種目・重量・回数が残ります。"))
                } else {
                    List(store.state.records) { record in
                        NavigationLink {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(record.date, format: .dateTime.year().month().day().hour().minute())
                                        .foregroundStyle(.secondary)
                                    ForEach(record.exercises) { exercise in
                                        ExerciseRow(exercise: exercise, showIncrement: false)
                                    }
                                    Text(record.increasedWeight ? "完了時に追加重量を次回へ反映しました。" : "次回も同じ重量で続けます。")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(20)
                            }
                            .background(Palette.background)
                            .navigationTitle(record.cycleName)
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2).foregroundStyle(Palette.accent)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(record.cycleName).font(.headline)
                                    Text(record.date, format: .dateTime.month().day().hour().minute())
                                        .font(.caption).foregroundStyle(.secondary)
                                    Text("\(record.exercises.count)種目を完了")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Palette.card)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Palette.background)
            .navigationTitle("トレーニング履歴")
        }
    }
}

