import SwiftUI

@main
struct VoxiOSApp: App {
    @State private var appState = iOSAppState()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if !appState.onboardingComplete {
                    iOSOnboardingView()
                        .environment(appState)
                } else {
                    iOSHomeView()
                        .environment(appState)
                }
            }
        }
    }
}
