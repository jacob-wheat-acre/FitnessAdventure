import SwiftUI
import Combine

@main
struct fittnessrpgApp: App {
    @StateObject var vm = GameViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack{
                RootView()
            }
                .environmentObject(vm)  //CRITICAL
        }
    }
}
