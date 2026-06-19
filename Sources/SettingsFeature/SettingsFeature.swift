import ComposableArchitecture
import Models
import SQLiteData
import Settings
import Sharing
import SwiftUI

@Reducer
public struct SettingsFeature {
  @ObservableState
  public struct State: Equatable {
    @Presents public var alert: AlertState<Action.Alert>?
    public init() {}
  }

  public enum Action {
    case alert(PresentationAction<Alert>)
    case resetStatsButtonTapped

    public enum Alert: Equatable {
      case confirmReset
    }
  }

  @Dependency(\.defaultDatabase) var database

  public init() {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .alert(.presented(.confirmReset)):
        let database = self.database
        return .run { _ in
          withErrorReporting {
            try database.write { db in
              try CompletedGame.delete().execute(db)
              try Achievement.delete().execute(db)
            }
          }
        }

      case .alert:
        return .none

      case .resetStatsButtonTapped:
        state.alert = AlertState {
          TextState("Reset all stats?")
        } actions: {
          ButtonState(role: .destructive, action: .confirmReset) { TextState("Reset") }
          ButtonState(role: .cancel) { TextState("Cancel") }
        } message: {
          TextState("This permanently deletes your game history and achievements.")
        }
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

public struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>
  @Shared(.userSettings) var settings

  public init(store: StoreOf<SettingsFeature>) {
    self.store = store
  }

  public var body: some View {
    Form {
      Section("Appearance") {
        Picker("Theme", selection: Binding($settings.appearance)) {
          ForEach(Appearance.allCases, id: \.self) { appearance in
            Text(appearance.title).tag(appearance)
          }
        }
      }

      Section("Game") {
        Toggle("Sound effects", isOn: Binding($settings.soundEnabled))
        Toggle("Haptics", isOn: Binding($settings.hapticsEnabled))
        Picker("Default board", selection: Binding($settings.defaultBoardSize)) {
          ForEach([3, 4, 5], id: \.self) { size in
            Text("\(size)×\(size)").tag(size)
          }
        }
      }

      Section {
        Button("Reset Stats", role: .destructive) {
          store.send(.resetStatsButtonTapped)
        }
      } footer: {
        Text("Deletes all saved games and achievements.")
      }
    }
    .formStyle(.grouped)
    .navigationTitle("Settings")
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}

extension Appearance {
  fileprivate var title: String {
    switch self {
    case .system: "System"
    case .light: "Light"
    case .dark: "Dark"
    }
  }

  /// SwiftUI color scheme, or `nil` to follow the system.
  public var colorScheme: ColorScheme? {
    switch self {
    case .system: nil
    case .light: .light
    case .dark: .dark
    }
  }
}
