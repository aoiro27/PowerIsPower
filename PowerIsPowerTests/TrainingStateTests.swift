import XCTest
@testable import PowerIsPower

final class TrainingStateTests: XCTestCase {
    func testPoundsDisplayIsIntegerIncludingEditorAfterUnitChange() {
        var exercise = Exercise(name: "ロー", weight: 59, increment: 2.5, reps: 10)
        exercise.changeUnit(to: .lbs)
        XCTAssertEqual(exercise.unit.displayText(exercise.weight, grouping: false), "131")
        XCTAssertEqual(exercise.unit.displayText(exercise.increment, grouping: false), "5")
        XCTAssertEqual(exercise.unit.displayText(exercise.weight), "131")
        XCTAssertEqual(WeightUnit.kg.displayText(2.5, grouping: false), 2.5.formatted(.number))
        XCTAssertEqual(exercise.weight, 59 / 0.45, accuracy: 0.0000001)
    }

    func testWeightConversionInBothDirections() {
        XCTAssertEqual(WeightUnit.lbs.convert(100, to: .kg), 45, accuracy: 0.0000001)
        XCTAssertEqual(WeightUnit.kg.convert(45, to: .lbs), 100, accuracy: 0.0000001)
        XCTAssertEqual(WeightUnit.lbs.convert(100, to: .lbs), 100)
        XCTAssertEqual(WeightUnit.kg.convert(0, to: .lbs), 0)
    }

    func testChangingUnitsConvertsWeightAndIncrementWithoutRounding() {
        var exercise = Exercise(name: "ロー", weight: 80, increment: 2.5, reps: 10)
        exercise.changeUnit(to: .lbs)
        XCTAssertEqual(exercise.weight, 80 / 0.45, accuracy: 0.0000001)
        XCTAssertEqual(exercise.increment, 2.5 / 0.45, accuracy: 0.0000001)
        for _ in 0..<100 {
            exercise.changeUnit(to: .kg)
            exercise.changeUnit(to: .lbs)
        }
        exercise.changeUnit(to: .kg)
        XCTAssertEqual(exercise.weight, 80, accuracy: 0.0000001)
        XCTAssertEqual(exercise.increment, 2.5, accuracy: 0.0000001)
    }

    func testLegacyStateAndHistoryDefaultToKilograms() throws {
        var original = TrainingState.sample
        original.complete(increaseWeight: true)
        let encoded = try JSONEncoder().encode(original)
        let json = String(decoding: encoded, as: UTF8.self)
            .replacingOccurrences(of: "\"unit\":\"kg\",", with: "")
            .replacingOccurrences(of: ",\"unit\":\"kg\"", with: "")
        XCTAssertFalse(json.contains("\"unit\""))
        let restored = try JSONDecoder().decode(TrainingState.self, from: Data(json.utf8))
        XCTAssertEqual(restored, original)
        XCTAssertEqual(restored.records[0].exercises[0].unit, .kg)
    }

    func testMixedUnitsIncreaseInTheirOwnUnitsAndSurviveSerialization() throws {
        var state = TrainingState.sample
        state.cycles[0].exercises.append(Exercise(name: "プレス", weight: 100, increment: 5, reps: 10, unit: .lbs))
        XCTAssertTrue(state.complete(increaseWeight: true))
        XCTAssertEqual(state.cycles[0].exercises[0].weight, 82.5)
        XCTAssertEqual(state.cycles[0].exercises[2].weight, 105)
        XCTAssertEqual(state.cycles[0].exercises[2].unit, .lbs)
        XCTAssertEqual(state.records[0].exercises[2].weight, 100)
        XCTAssertEqual(state.records[0].exercises[2].unit, .lbs)
        let restored = try JSONDecoder().decode(TrainingState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored, state)
        XCTAssertTrue(state.complete(increaseWeight: false))
        XCTAssertEqual(state.cycles[0].exercises[2].weight, 105)
    }

    func testPoundsLimitsUseKilogramEquivalent() {
        XCTAssertTrue(Exercise(name: "ロー", weight: 15_000, increment: 1_500, reps: 10, unit: .lbs).isValid)
        XCTAssertFalse(Exercise(name: "ロー", weight: 25_000, increment: 0, reps: 10, unit: .lbs).isValid)
        var state = TrainingState.sample
        state.cycles[0].exercises = [Exercise(name: "ロー", weight: 22_200, increment: 100, reps: 10, unit: .lbs)]
        let original = state
        XCTAssertFalse(state.complete(increaseWeight: true))
        XCTAssertEqual(state, original)
    }

    func testCompletionPreservesPerformedWeightsAndIncreasesOnlyCompletedCycle() {
        var state = TrainingState.sample
        let second = TrainingCycle(name: "サイクル2", exercises: [
            Exercise(name: "チェストプレス", weight: 40, increment: 2.5, reps: 10)
        ])
        state.save(second)
        XCTAssertTrue(state.complete(increaseWeight: true))
        XCTAssertEqual(state.nextCycleID, second.id)
        XCTAssertEqual(state.records.first?.exercises.map(\.weight), [80, 100])
        XCTAssertEqual(state.cycles[0].exercises.map(\.weight), [82.5, 105])
        XCTAssertEqual(state.cycles[1].exercises[0].weight, 40)
        XCTAssertTrue(state.complete(increaseWeight: false))
        XCTAssertEqual(state.nextCycleID, state.cycles[0].id)
        XCTAssertEqual(state.cycles[1].exercises[0].weight, 40)
    }

    func testSingleCycleRepeatsAndRecordsSurviveDeletion() {
        var state = TrainingState.sample
        let cycleID = state.cycles[0].id
        state.complete(increaseWeight: false)
        XCTAssertEqual(state.nextCycleID, cycleID)
        state.delete(cycleID)
        XCTAssertNil(state.nextCycle)
        XCTAssertEqual(state.records.count, 1)
        XCTAssertFalse(state.complete(increaseWeight: true))
    }

    func testDeletingNextCycleSelectsItsSuccessor() {
        var state = TrainingState.sample
        let second = TrainingCycle(name: "2", exercises: state.cycles[0].exercises)
        let third = TrainingCycle(name: "3", exercises: state.cycles[0].exercises)
        state.save(second)
        state.save(third)
        state.nextCycleID = second.id
        state.delete(second.id)
        XCTAssertEqual(state.nextCycleID, third.id)
    }

    func testSerializationRetainsProgressAndHistory() throws {
        var state = TrainingState.sample
        state.complete(increaseWeight: true)
        let data = try JSONEncoder().encode(state)
        XCTAssertEqual(try JSONDecoder().decode(TrainingState.self, from: data), state)
    }

    func testValidationAndWeightLimitDoNotMutateState() {
        XCTAssertFalse(TrainingCycle(name: "空", exercises: []).isValid)
        XCTAssertFalse(Exercise(name: " ", weight: 10, increment: 0, reps: 10).isValid)
        XCTAssertFalse(Exercise(name: "ロー", weight: .nan, increment: 0, reps: 10).isValid)
        XCTAssertFalse(Exercise(name: "ロー", weight: 10, increment: -1, reps: 10).isValid)
        XCTAssertFalse(Exercise(name: "ロー", weight: 10, increment: 0, reps: 0).isValid)
        var state = TrainingState.sample
        state.cycles[0].exercises[0].weight = 10_000
        let original = state
        XCTAssertFalse(state.complete(increaseWeight: true))
        XCTAssertEqual(state, original)
    }
}
