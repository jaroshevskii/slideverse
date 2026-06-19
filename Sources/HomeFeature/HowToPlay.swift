import ComposableArchitecture
import SwiftUI

@Reducer
public struct HowToPlay {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action {}

  public init() {}

  public var body: some Reducer<State, Action> {
    EmptyReducer()
  }
}

public struct HowToPlayView: View {
  let store: StoreOf<HowToPlay>

  public init(store: StoreOf<HowToPlay>) {
    self.store = store
  }

  public var body: some View {
    List {
      Section {
        instruction("hand.tap.fill", "Tap a tile next to the empty space to slide it in.")
        instruction(
          "checkmark.seal.fill", "Arrange the tiles in order, with the blank in the bottom-right.")
        instruction(
          "lightbulb.fill",
          "Stuck? Use a Hint for the next best move, or Auto-solve to watch it finish.")
        instruction("timer", "You're scored on speed and moves — hints reduce your score.")
        instruction("calendar", "The Daily Challenge gives everyone the same board each day.")
      }
    }
    .navigationTitle("How to Play")
  }

  private func instruction(_ systemImage: String, _ text: String) -> some View {
    Label {
      Text(text)
    } icon: {
      Image(systemName: systemImage)
        .foregroundStyle(.orange)
    }
    .padding(.vertical, 4)
  }
}
