import SwiftUI
import SwiftData

@main
struct SaVurApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(Theme.ink)
        }
        .modelContainer(for: FoodPhoto.self)
    }
}
