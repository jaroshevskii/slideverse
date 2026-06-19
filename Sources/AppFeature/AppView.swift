import ComposableArchitecture
import GameFeature
import HomeFeature
import Settings
import SettingsFeature
import Sharing
import StatsFeature
import SwiftUI

public struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>
  @Namespace private var playTransition
  @Shared(.userSettings) private var settings

  public init(store: StoreOf<AppReducer>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      HomeView(
        store: store.scope(state: \.home, action: \.home),
        playTransition: playTransition
      )
    } destination: { store in
      switch store.case {
      case .game(let store):
        GameView(store: store)
          #if os(iOS)
            .navigationTransition(.zoom(sourceID: "play", in: playTransition))
          #endif
      case .howToPlay(let store):
        HowToPlayView(store: store)
      case .settings(let store):
        SettingsView(store: store)
      case .stats(let store):
        StatsView(store: store)
      }
    }
    .preferredColorScheme(settings.appearance.colorScheme)
  }
}

#Preview {
  AppView(
    store: Store(initialState: AppReducer.State()) {
      AppReducer()
    }
  )
}
