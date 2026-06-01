import ComposableArchitecture
import SwiftUI

@Reducer
public struct Home {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action {
    case dailyButtonTapped
    case howToButtonTapped
    case playButtonTapped
    case settingsButtonTapped
    case statsButtonTapped
  }

  public init() {}

  public var body: some Reducer<State, Action> {
    // Navigation is owned by the parent (AppReducer); Home just emits intents.
    EmptyReducer()
  }
}

public struct HomeView: View {
  let store: StoreOf<Home>
  let playTransition: Namespace.ID

  public init(store: StoreOf<Home>, playTransition: Namespace.ID) {
    self.store = store
    self.playTransition = playTransition
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        header

        Button {
          store.send(.playButtonTapped)
        } label: {
          Label("Play", systemImage: "play.fill")
            .font(.title2.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.extraLarge)
        .matchedTransitionSource(id: "play", in: playTransition)

        Button {
          store.send(.dailyButtonTapped)
        } label: {
          Label("Daily Challenge", systemImage: "calendar")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)

        VStack(spacing: 0) {
          menuRow("Stats", systemImage: "chart.bar.fill") { store.send(.statsButtonTapped) }
          Divider().padding(.leading, 52)
          menuRow("Settings", systemImage: "gearshape.fill") { store.send(.settingsButtonTapped) }
          Divider().padding(.leading, 52)
          menuRow("How to Play", systemImage: "questionmark.circle.fill") {
            store.send(.howToButtonTapped)
          }
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
      }
      .padding()
    }
    .navigationTitle("Slideverse")
  }

  private var header: some View {
    VStack(spacing: 8) {
      Image(systemName: "square.grid.3x3.fill")
        .font(.system(size: 64))
        .foregroundStyle(.orange.gradient)
        .symbolEffect(.pulse)
      Text("Slide the tiles into order")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(.top, 24)
  }

  private func menuRow(
    _ title: String,
    systemImage: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Image(systemName: systemImage)
          .font(.title3)
          .frame(width: 28)
          .foregroundStyle(.orange)
        Text(title)
        Spacer()
        Image(systemName: "chevron.right")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(.vertical, 14)
      .padding(.horizontal, 16)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
  }
}
