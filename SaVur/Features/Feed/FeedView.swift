import SwiftUI

/// Placeholder until Stage 6 (friends + weekly-card feed).
struct FeedView: View {
    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "person.2")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.inkSoft)

                Text("Friends, week to week")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                Text("Your friends' organic weeks will show up here.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }
}

#Preview {
    FeedView()
}
