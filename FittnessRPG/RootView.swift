
import SwiftUI
import Combine

struct RootView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        Group {
            if vm.player.name.isEmpty {
                CharacterCreationView()
            } else {
                MainMenuView()
            }
        }
    }
}
