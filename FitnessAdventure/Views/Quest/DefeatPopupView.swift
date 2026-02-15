import SwiftUI

struct DefeatPopupView: View {
    let enemyName: String
    let message: String
    let onDone: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("\(enemyName) Defeated")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: onDone) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding(20)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)
        }
    }
}

