import ComposableArchitecture
import GameFeature
import HomeFeature
import Models
import Settings
import SettingsFeature
import Sharing
import StatsFeature

@Reducer
public struct AppReducer {
  @Reducer
  public enum Path {
    case game(Game)
    case howToPlay(HowToPlay)
    case settings(SettingsFeature)
    case stats(Stats)
  }

  @ObservableState
  public struct State: Equatable {
    public var home: Home.State
    public var path: StackState<Path.State>

    @ObservationStateIgnored
    @Shared(.userSettings) public var settings: UserSettings

    public init(home: Home.State = Home.State(), path: StackState<Path.State> = StackState()) {
      self.home = home
      self.path = path
    }
  }

  public enum Action {
    case home(Home.Action)
    case path(StackActionOf<Path>)
  }

  public init() {}

  public var body: some Reducer<State, Action> {
    Scope(state: \.home, action: \.home) {
      Home()
    }
    Reduce { state, action in
      switch action {
      case .home(.dailyButtonTapped):
        state.path.append(.game(Game.State(boardSize: 4, mode: .daily)))
        return .none

      case .home(.howToButtonTapped):
        state.path.append(.howToPlay(HowToPlay.State()))
        return .none

      case .home(.playButtonTapped):
        state.path.append(.game(Game.State(boardSize: state.settings.defaultBoardSize)))
        return .none

      case .home(.settingsButtonTapped):
        state.path.append(.settings(SettingsFeature.State()))
        return .none

      case .home(.statsButtonTapped):
        state.path.append(.stats(Stats.State()))
        return .none

      case .home, .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension AppReducer.Path.State: Equatable {}
