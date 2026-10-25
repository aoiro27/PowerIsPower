import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TrainingStore

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("トレーニング", systemImage: "dumbbell.fill") }
            CyclesView()
                .tabItem { Label("サイクル", systemImage: "arrow.triangle.2.circlepath") }
            HistoryView()
                .tabItem { Label("履歴", systemImage: "clock.arrow.circlepath") }
        }
        .disabled(!store.isLoaded)
        .alert("データを確認してください", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            if !store.isLoaded {
                Button("再読み込み") { store.load() }
            }
            Button("閉じる", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

struct TodayView: View {
    @EnvironmentObject private var store: TrainingStore
    @State private var showCompletion = false
    @State private var editingCycle: TrainingCycle?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Label("POWER IS POWER", systemImage: "bolt.fill")
                            .font(.caption.weight(.heavy))
                            .tracking(2)
                            .foregroundStyle(Palette.accent)
                        Spacer()
                        Text(Date.now, format: .dateTime.month().day())
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Text("今日も、一歩強く。")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    if let cycle = store.state.nextCycle {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("NEXT TRAINING").font(.caption.weight(.bold)).tracking(2)
                                Spacer()
                                Text("\((store.state.cycles.firstIndex(where: { $0.id == cycle.id }) ?? 0) + 1) / \(store.state.cycles.count)")
                                    .font(.system(.subheadline, design: .monospaced))
                            }
                            .foregroundStyle(.black.opacity(0.65))
                            Text(cycle.name).font(.largeTitle.bold()).foregroundStyle(.black)
                            Text("\(cycle.exercises.count)種目 · 自分のペースで積み重ねよう")
                                .font(.subheadline).foregroundStyle(.black.opacity(0.75))
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.accent, in: RoundedRectangle(cornerRadius: 26))

                        HStack {
                            Text("今回のメニュー").font(.headline)
                            Spacer()
                            Button("編集") { editingCycle = cycle }
                        }
                        VStack(spacing: 12) {
                            ForEach(cycle.exercises) { exercise in
                                ExerciseRow(exercise: exercise)
                            }
                        }
                        PrimaryButton(title: "トレーニングを完了", symbol: "checkmark") {
                            showCompletion = true
                        }
                        Text("完了すると次のサイクルへ進みます。\n最後のサイクルの次は、最初に戻ります。")
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                    } else {
                        ContentUnavailableView("最初のサイクルを作ろう", systemImage: "dumbbell",
                                               description: Text("1日に行う種目・重量・回数をまとめて登録します。"))
                        PrimaryButton(title: "サイクルを作成", symbol: "plus") {
                            editingCycle = TrainingCycle(name: "サイクル1", exercises: [])
                        }
                    }
                }
                .padding(20)
            }
            .background(Palette.background)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editingCycle) { CycleEditor(cycle: $0) }
            .sheet(isPresented: $showCompletion) { CompletionView() }
        }
    }
}

struct CompletionView: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    @State private var increaseWeight = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(store.state.nextCycle?.name ?? "")
                        .font(.title2.bold())
                    Text("今回のメニューを履歴に保存し、次のサイクルへ進みます。")
                        .foregroundStyle(.secondary)
                }
                Section {
                    Toggle("次回の重量を増やす", isOn: $increaseWeight)
                    if let cycle = store.state.nextCycle {
                        ForEach(cycle.exercises) { exercise in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(exercise.name).font(.headline)
                                Text("今回：\(exercise.unit.dualText(exercise.weight))")
                                    .foregroundStyle(.secondary)
                                Text("次回：\(exercise.unit.dualText(exercise.weight + (increaseWeight ? exercise.increment : 0)))")
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                    }
                } footer: {
                    Text("このサイクルを次に行う際の重量です。オフにすると、今回と同じ重量を維持します。")
                }
                Section {
                    Button("完了して記録する") {
                        if store.complete(increaseWeight: increaseWeight) { dismiss() }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("おつかれさまでした")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}
