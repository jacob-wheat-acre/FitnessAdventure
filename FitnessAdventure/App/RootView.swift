import SwiftUI

struct RootView: View {
    @EnvironmentObject var vm: GameViewModel
    @AppStorage("hasSeenOpeningHook") private var hasSeenOpeningHook: Bool = false

    var body: some View {
        Group {
            if !hasSeenOpeningHook {
                OpeningHookView()
            } else if vm.player.name.isEmpty {
                CharacterCreationView(vm: vm)
            } else {
                MainMenuView(vm: vm)
            }
        }
        .sheet(item: $vm.activeSheet) { (sheet: ActiveSheet) in
            switch sheet {
            case .attackChoice:
                AttackChoiceView(vm: vm, choices: vm.attackChoices)

            case .levelUp(let snapshot):
                LevelUpView(snapshot: snapshot, vm: vm)

            case .trophyDetail(let model):
                TrophyDetailSheet(title: model.title, text: model.text)

            case .manualEntry:
                NavigationStack {
                    ManualWorkoutEntryView { newSession in
                        vm.addManualSession(newSession)
                        vm.dismissActiveSheet()
                        vm.savePlayer()
                    }
                }

            case .applyAllSummary:
                NavigationStack {
                    ApplyAllSummaryView(summary: vm.applyAllSummary, vm: vm)
                }
            }
        }
    }
}
