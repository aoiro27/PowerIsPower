import SwiftUI

@main
struct PowerIsPowerApp: App {
    @StateObject private var store = TrainingStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Palette.accent)
        }
    }
}

