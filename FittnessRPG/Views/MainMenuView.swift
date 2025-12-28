
import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var animateXP: CGFloat = 0
    @State private var animateDistance: CGFloat = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {

                Text("Welcome, \(vm.player.name)")
                    .font(.largeTitle)
                    .bold()

                Text("\(vm.player.species.rawValue) \(vm.player.playerClass.rawValue)")
                    .font(.title2)

                // LEVEL DISPLAY
                Text("Level \(vm.player.level)")
                    .font(.title)
                    .bold()

                // XP BAR
                VStack(alignment: .leading) {
                    Text("XP: \(Int(vm.player.experience))/\(Int(vm.player.xpForNextLevel))")
                        .font(.caption)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 12)
                                .cornerRadius(6)

                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geo.size.width * animateXP, height: 12)
                                .cornerRadius(6)
                        }
                    }
                    .frame(height: 12)
                }
                .padding(.horizontal)

                // DISTANCE BAR
                VStack(alignment: .leading) {
                    Text("Miles Journeyed: \(String(format: "%.1f", vm.player.distanceProgress))")
                        .font(.caption)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 12)
                                .cornerRadius(6)

                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geo.size.width * animateDistance, height: 12)
                                .cornerRadius(6)
                        }
                    }
                    .frame(height: 12)
                }
                .padding(.horizontal)

                // BUTTONS
                VStack(spacing: 20) {

                    NavigationLink("Workouts") {
                        WorkoutChoiceView()
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink("Quests") {
                        QuestSelectionView()
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink("Skill Tree") {
                        SkillTreeView()
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        vm.resetPlayer()
                    } label: {
                        Text("Reset Character")
                            .padding(.top, 10)
                    }
                }

                Spacer()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animateXP = vm.player.xpProgress
                    animateDistance = min(vm.player.distanceProgress / 100, 1) // visual scale
                }
            }
            .sheet(isPresented: $vm.showAttackChoiceSheet) {
                AttackChoiceView(choices: vm.attackChoices)
                    .environmentObject(vm)
            }
        }
    }
}
