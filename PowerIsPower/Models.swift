import Foundation

enum WeightUnit: String, Codable, CaseIterable {
    case kg
    case lbs

    var label: String { self == .kg ? "kg" : "LBS" }
    var other: WeightUnit { self == .kg ? .lbs : .kg }

    func convert(_ value: Double, to target: WeightUnit) -> Double {
        guard self != target else { return value }
        return self == .lbs ? value * 0.45 : value / 0.45
    }

    func dualText(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        return "\(value.weightText) \(label)（≈ \(convertedText(value))）"
    }

    func convertedText(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        let integer = convert(value, to: other).rounded(.towardZero)
        return "\(integer.formatted(.number.precision(.fractionLength(0)))) \(other.label)"
    }
}

struct Exercise: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var weight: Double
    var increment: Double
    var reps: Int
    var unit: WeightUnit = .kg

    init(id: UUID = UUID(), name: String, weight: Double, increment: Double, reps: Int, unit: WeightUnit = .kg) {
        self.id = id
        self.name = name
        self.weight = weight
        self.increment = increment
        self.reps = reps
        self.unit = unit
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        weight = try values.decode(Double.self, forKey: .weight)
        increment = try values.decode(Double.self, forKey: .increment)
        reps = try values.decode(Int.self, forKey: .reps)
        unit = try values.decodeIfPresent(WeightUnit.self, forKey: .unit) ?? .kg
    }

    mutating func changeUnit(to newUnit: WeightUnit) {
        weight = unit.convert(weight, to: newUnit)
        increment = unit.convert(increment, to: newUnit)
        unit = newUnit
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && weight.isFinite && (0...10_000).contains(unit.convert(weight, to: .kg))
            && increment.isFinite && (0...1_000).contains(unit.convert(increment, to: .kg))
            && (1...1_000).contains(reps)
    }
}

struct TrainingCycle: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var exercises: [Exercise]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !exercises.isEmpty && exercises.allSatisfy(\.isValid)
    }
}

struct TrainingRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var cycleName: String
    var exercises: [Exercise]
    var increasedWeight: Bool
}

struct TrainingState: Codable, Equatable {
    var cycles: [TrainingCycle] = []
    var nextCycleID: UUID?
    var records: [TrainingRecord] = []

    var nextCycle: TrainingCycle? {
        cycles.first { $0.id == nextCycleID } ?? cycles.first
    }

    mutating func save(_ cycle: TrainingCycle) {
        guard cycle.isValid else { return }
        if let index = cycles.firstIndex(where: { $0.id == cycle.id }) {
            cycles[index] = cycle
        } else {
            cycles.append(cycle)
        }
        if nextCycleID == nil { nextCycleID = cycles.first?.id }
    }

    mutating func delete(_ cycleID: UUID) {
        guard let index = cycles.firstIndex(where: { $0.id == cycleID }) else { return }
        let successor = cycles.count > 1 ? cycles[(index + 1) % cycles.count].id : nil
        cycles.remove(at: index)
        if nextCycleID == cycleID { nextCycleID = successor }
    }

    @discardableResult
    mutating func complete(increaseWeight: Bool, date: Date = Date()) -> Bool {
        guard let cycle = nextCycle, cycle.isValid,
              let index = cycles.firstIndex(where: { $0.id == cycle.id }) else { return false }
        if increaseWeight && cycle.exercises.contains(where: { $0.unit.convert($0.weight + $0.increment, to: .kg) > 10_000 }) {
            return false
        }
        records.insert(TrainingRecord(date: date, cycleName: cycle.name,
                                      exercises: cycle.exercises, increasedWeight: increaseWeight), at: 0)
        if increaseWeight {
            for exerciseIndex in cycles[index].exercises.indices {
                cycles[index].exercises[exerciseIndex].weight += cycles[index].exercises[exerciseIndex].increment
            }
        }
        nextCycleID = cycles[(index + 1) % cycles.count].id
        return true
    }

    static var sample: TrainingState {
        let first = TrainingCycle(name: "サイクル1", exercises: [
            Exercise(name: "シーテッドロー", weight: 80, increment: 2.5, reps: 10),
            Exercise(name: "レッグプレス", weight: 100, increment: 5, reps: 10)
        ])
        return TrainingState(cycles: [first], nextCycleID: first.id)
    }
}

extension Double {
    var weightText: String {
        formatted(.number.precision(.fractionLength(0...2)))
    }
}
