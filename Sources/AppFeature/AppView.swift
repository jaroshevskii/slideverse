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
      case let .game(store):
        GameView(store: store)
          #if os(iOS)
            .navigationTransition(.zoom(sourceID: "play", in: playTransition))
          #endif
      case let .howToPlay(store):
        HowToPlayView(store: store)
      case let .settings(store):
        SettingsView(store: store)
      case let .stats(store):
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
