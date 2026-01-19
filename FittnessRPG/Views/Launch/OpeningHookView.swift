import SwiftUI

struct OpeningHookView: View {
    @AppStorage("hasSeenOpeningHook") private var hasSeenOpeningHook: Bool = false

    var body: some View {
        VStack(spacing: 28) {

            Spacer()

            Text("The Path: Fitness Adventure")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("""
The rulers of the lands have sown the seeds of complacency in the citizenry. This had caused a downward trend into passive consumptionism.

No more! You are on an epic quest to walk the ancient paths, encounter the fantastical, and reignite the spirit of ADVENTURE.
""")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button {
                hasSeenOpeningHook = true
            } label: {
                Text("Begin Your Journey")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }
}
