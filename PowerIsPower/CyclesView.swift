import SwiftUI

struct CyclesView: View {
    @EnvironmentObject private var store: TrainingStore
    @State private var editingCycle: TrainingCycle?
    @State private var deletingCycle: TrainingCycle?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("1日分のメニューを1サイクルに。\n上から順に繰り返していきます。")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
                Section {
                    ForEach(store.state.cycles) { cycle in
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                editingCycle = cycle
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(cycle.name).font(.title3.bold()).foregroundStyle(.primary)
                                        Spacer()
                                        if store.state.nextCycle?.id == cycle.id {
                                            Text("次回").font(.caption.bold())
                                                .padding(.horizontal, 10).padding(.vertical, 5)
                                                .background(Palette.accent.opacity(0.15), in: Capsule())
                                        }
                                        Image(systemName: "chevron.right").font(.caption)
                                    }
                                    ForEach(cycle.exercises) { exercise in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name).font(.subheadline)
                                            Text("\(exercise.unit.dualText(exercise.weight)) × \(exercise.reps)回")
                                            Text("追加 +\(exercise.unit.dualText(exercise.increment))")
                                        }
                                        .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if store.state.nextCycle?.id != cycle.id {
                                Button("次回はこのサイクルを行う") {
                                    store.update { $0.nextCycleID = cycle.id }
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Palette.card)
                        .swipeActions {
                            Button("削除", role: .destructive) { deletingCycle = cycle }
                        }
                    }
                    .onMove { source, destination in
                        store.update { $0.cycles.move(fromOffsets: source, toOffset: destination) }
                    }
                } footer: {
                    Text("「並べ替え」で順序を変更できます。左へスワイプすると削除できます。")
                }
                Button {
                    editingCycle = TrainingCycle(name: "サイクル\(store.state.cycles.count + 1)", exercises: [])
                } label: {
                    Label("サイクルを追加", systemImage: "plus.circle.fill").font(.headline)
                }
                .listRowBackground(Palette.card)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("サイクル")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { EditButton() } }
            .sheet(item: $editingCycle) { CycleEditor(cycle: $0) }
            .confirmationDialog("\(deletingCycle?.name ?? "サイクル")を削除しますか？", isPresented: Binding(
                get: { deletingCycle != nil }, set: { if !$0 { deletingCycle = nil } }
            ), titleVisibility: .visible) {
                Button("サイクルを削除", role: .destructive) {
                    if let cycle = deletingCycle { store.update { $0.delete(cycle.id) } }
                    deletingCycle = nil
                }
            } message: {
                Text("過去のトレーニング履歴は残ります。")
            }
        }
        .environment(\.locale, Locale(identifier: "ja_JP"))
    }
}

struct CycleEditor: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    @State var cycle: TrainingCycle

    var body: some View {
        NavigationStack {
            Form {
                Section("サイクル名") {
                    TextField("例：サイクル1 / 背中・脚", text: $cycle.name)
                }
                ForEach($cycle.exercises) { $exercise in
                    Section {
                        TextField("種目名", text: $exercise.name)
                            .font(.headline)
                        Picker("入力単位", selection: Binding(
                            get: { exercise.unit },
                            set: { exercise.changeUnit(to: $0) }
                        )) {
                            ForEach(WeightUnit.allCases, id: \.self) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("入力単位")
                        NumberField(title: "重量", unit: exercise.unit.label, value: $exercise.weight)
                            .id("weight-\(exercise.unit.rawValue)")
                        Text(exercise.unit.dualText(exercise.weight))
                            .font(.caption).foregroundStyle(.secondary)
                        NumberField(title: "追加重量", unit: exercise.unit.label, value: $exercise.increment)
                            .id("increment-\(exercise.unit.rawValue)")
                        Text(exercise.unit.dualText(exercise.increment))
                            .font(.caption).foregroundStyle(.secondary)
                        RepsField(value: $exercise.reps)
                        Button("この種目を削除", role: .destructive) {
                            cycle.exercises.removeAll { $0.id == exercise.id }
                        }
                        .font(.subheadline)
                    }
                }
                Section {
                    Button {
                        cycle.exercises.append(Exercise(name: "", weight: 0, increment: 0, reps: 10))
                    } label: {
                        Label("種目を追加", systemImage: "plus.circle.fill")
                    }
                } footer: {
                    Text("種目ごとにkg／LBSを選べます。単位を切り替えると入力済みの重量・追加重量も換算されます。換算表示は小数点以下を切り捨てた整数です。\n追加重量は完了時に次回の重量へ加算する値です。0にすると重量を維持します。\nkg換算で重量：0〜10,000kg / 追加重量：0〜1,000kg / 回数：1〜1,000回。種目を1つ以上登録してください。")
                }
            }
            .navigationTitle("サイクルを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        cycle.name = cycle.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        for index in cycle.exercises.indices {
                            cycle.exercises[index].name = cycle.exercises[index].name.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        if store.update({ $0.save(cycle) }) { dismiss() }
                    }
                    .disabled(!cycle.isValid)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

struct NumberField: View {
    let title: String
    let unit: String
    @Binding var value: Double
    @State private var text = ""

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 16)
            TextField(title, text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    value = (try? Double(newValue, format: .number.locale(.current))) ?? .nan
                }
            ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .accessibilityLabel(title)
            Text(unit).foregroundStyle(.secondary)
        }
        .onAppear { text = value.isFinite ? value.formatted(.number.grouping(.never).precision(.fractionLength(0...6))) : "" }
    }
}

struct RepsField: View {
    @Binding var value: Int
    @State private var text = ""

    var body: some View {
        HStack {
            Text("回数")
            Spacer(minLength: 16)
            TextField("回数", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .accessibilityLabel("回数")
            Text("回").foregroundStyle(.secondary)
        }
        .onAppear { text = String(value) }
        .onChange(of: text) { _, newValue in value = Int(newValue) ?? 0 }
    }
}
