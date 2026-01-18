import SwiftUI

struct RootView: View {
    @EnvironmentObject var vm: GameViewModel

    // Hook should be re-showable; we will clear this flag on character reset.
    @AppStorage("hasSeenOpeningHook") private var hasSeenOpeningHook: Bool = false

    var body: some View {
        Group {
            // Show hook first, before character creation, if the flag is false.
            if !hasSeenOpeningHook {
                OpeningHookView()
            } else if vm.player.name.isEmpty {
                CharacterCreationView(vm: vm)
            } else {
                MainMenuView(vm: vm)
            }
        }
    }
}
