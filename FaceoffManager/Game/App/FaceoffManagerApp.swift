import SwiftUI

@main
struct FaceoffManagerApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
