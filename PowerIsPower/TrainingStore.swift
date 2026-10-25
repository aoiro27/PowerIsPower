import Foundation
import SwiftUI

@MainActor
final class TrainingStore: ObservableObject {
    @Published private(set) var state = TrainingState()
    @Published var errorMessage: String?
    @Published private(set) var isLoaded = false
    private let fileURL: URL

    init() {
        fileURL = URL.applicationSupportDirectory.appending(path: "PowerIsPower/training.json")
        load()
    }

    func load() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                state = try JSONDecoder().decode(TrainingState.self, from: Data(contentsOf: fileURL))
            } else {
                state = .sample
            }
            isLoaded = true
        } catch {
            errorMessage = "保存データを読み込めませんでした。データの上書きを防ぐため、変更を停止しています。\n\(error.localizedDescription)"
        }
    }

    @discardableResult
    func update(_ change: (inout TrainingState) -> Void) -> Bool {
        guard isLoaded else { return false }
        var updated = state
        change(&updated)
        do {
            let data = try JSONEncoder().encode(updated)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
            state = updated
            return true
        } catch {
            errorMessage = "保存できませんでした。変更は反映されていません。\n\(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func complete(increaseWeight: Bool) -> Bool {
        var preview = state
        guard preview.complete(increaseWeight: increaseWeight) else {
            errorMessage = "重量の上限は10,000kgです。追加重量を見直してください。"
            return false
        }
        return update { $0 = preview }
    }
}

