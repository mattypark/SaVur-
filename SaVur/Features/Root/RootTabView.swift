import SwiftUI

struct RootTabView: View {
    private enum Tab {
        case friends
        case capture
        case profile
    }

    // Open on your own week, Retro-style.
    @State private var selectedTab: Tab = .capture

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
                .tag(Tab.friends)

            CaptureView()
                .tabItem {
                    Label("SaVur", systemImage: "camera.on.rectangle")
                }
                .tag(Tab.capture)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(Tab.profile)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: FoodPhoto.self, inMemory: true)
}
