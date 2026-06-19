import ComposableArchitecture
import Models
import PuzzleCore
import Styleguide
import SwiftUI

public struct GameView: View {
  @Bindable var store: StoreOf<Game>
  @Namespace private var tileNamespace

  public init(store: StoreOf<Game>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 24) {
      statsBar
      boardGrid
        .overlay { if store.isGameOver { victoryOverlay } }
      controls
    }
    .padding()
    .navigationTitle(store.mode == .daily ? "Daily Challenge" : "Slideverse")
    .task { store.send(.task) }
  }

  private var statsBar: some View {
    HStack {
      Label {
        Text(timeString(store.secondsElapsed))
          .contentTransition(.numericText())
      } icon: {
        Image(systemName: store.isPaused ? "pause.circle.fill" : "clock")
      }
      Spacer()
      Label {
        Text("\(store.lastScore > 0 ? store.lastScore : store.moveCount)")
          .contentTransition(.numericText(value: Double(store.moveCount)))
      } icon: {
        Image(systemName: store.lastScore > 0 ? "star.fill" : "arrow.left.arrow.right")
      }
    }
    .font(.puzzleStat())
    .foregroundStyle(.secondary)
    .monospacedDigit()
  }

  private var boardGrid: some View {
    GeometryReader { proxy in
      let count = store.board.size
      let spacing = Styleguide.tileSpacing
      let side =
        (min(proxy.size.width, proxy.size.height)
          - spacing * CGFloat(count - 1)) / CGFloat(count)
      LazyVGrid(
        columns: Array(repeating: GridItem(.fixed(side), spacing: spacing), count: count),
        spacing: spacing
      ) {
        ForEach(Array(store.board.tiles.enumerated()), id: \.element) { index, tile in
          TileView(
            tile: tile,
            side: side,
            isHinted: store.hintIndex == index
          ) {
            store.send(.tileTapped(index), animation: .snappy)
          }
          .matchedGeometryEffect(id: tile, in: tileNamespace)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .blur(radius: store.isPaused ? 12 : 0)
      .overlay { if store.isPaused { pausedOverlay } }
    }
    .aspectRatio(1, contentMode: .fit)
  }

  private var controls: some View {
    VStack(spacing: 16) {
      if store.mode == .classic {
        Picker("Board size", selection: $store.boardSize.sending(\.boardSizeChanged)) {
          ForEach([3, 4, 5], id: \.self) { size in
            Text("\(size)×\(size)").tag(size)
          }
        }
        .pickerStyle(.segmented)
      }

      HStack(spacing: 12) {
        controlButton("Undo", systemImage: "arrow.uturn.backward") {
          store.send(.undoButtonTapped, animation: .snappy)
        }
        .disabled(!store.canUndo)

        controlButton(
          store.isPaused ? "Resume" : "Pause",
          systemImage: store.isPaused ? "play.fill" : "pause.fill"
        ) {
          store.send(.pauseButtonTapped, animation: .snappy)
        }
        .disabled(store.isGameOver)

        if store.canUseSolver {
          controlButton("Hint", systemImage: "lightbulb.fill") {
            store.send(.hintButtonTapped)
          }
          .disabled(store.isGameOver || store.isSolving || store.isAutoSolving)
          .symbolEffect(.bounce, value: store.hintIndex)
        }
      }

      HStack(spacing: 12) {
        if store.canUseSolver {
          Button {
            store.send(.autoSolveButtonTapped)
          } label: {
            Label("Auto-solve", systemImage: "wand.and.stars")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .disabled(store.isGameOver || store.isAutoSolving)
        }

        Button {
          store.send(.newGameButtonTapped, animation: .snappy)
        } label: {
          Label("New Game", systemImage: "shuffle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
      }
      .controlSize(.large)
    }
  }

  private func controlButton(
    _ title: String,
    systemImage: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Label(title, systemImage: systemImage)
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.bordered)
    .controlSize(.large)
  }

  private var pausedOverlay: some View {
    ContentUnavailableView("Paused", systemImage: "pause.circle.fill")
      .allowsHitTesting(false)
  }

  private var victoryOverlay: some View {
    ZStack {
      Rectangle().fill(.ultraThinMaterial)
      ConfettiView(trigger: store.confettiID)
      VStack(spacing: 10) {
        Image(systemName: "trophy.fill")
          .font(.system(size: 52))
          .foregroundStyle(.yellow)
          .symbolEffect(.bounce, value: store.confettiID)
        Text(store.isNewBest ? "New Best!" : "Solved!")
          .font(.largeTitle.bold())
        Text(
          "\(store.lastScore) pts · \(store.moveCount) moves · \(timeString(store.secondsElapsed))"
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
        if !store.unlockedAchievements.isEmpty {
          unlockedAchievements
        }
        Button("Play Again") {
          store.send(.newGameButtonTapped, animation: .snappy)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.top, 4)
      }
      .padding(32)
      .multilineTextAlignment(.center)
    }
    .clipShape(RoundedRectangle(cornerRadius: Styleguide.tileCornerRadius))
    .transition(.opacity.combined(with: .scale))
  }

  private var unlockedAchievements: some View {
    VStack(spacing: 4) {
      ForEach(store.unlockedAchievements, id: \.self) { key in
        Label(key.title, systemImage: "rosette")
          .font(.caption.weight(.medium))
          .foregroundStyle(.orange)
      }
    }
    .padding(.vertical, 4)
  }

  private func timeString(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let secs = seconds % 60
    if minutes >= 60 {
      return String(format: "%d:%02d:%02d", minutes / 60, minutes % 60, secs)
    }
    return String(format: "%02d:%02d", minutes, secs)
  }
}

private struct TileView: View {
  let tile: Tile
  let side: CGFloat
  let isHinted: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        RoundedRectangle(cornerRadius: Styleguide.tileCornerRadius)
          .fill(tile == .empty ? Styleguide.emptyTile.opacity(0.15) : Styleguide.tile)
          .overlay {
            if isHinted {
              RoundedRectangle(cornerRadius: Styleguide.tileCornerRadius)
                .strokeBorder(.white, lineWidth: 4)
            }
          }
        if let number = tile.number {
          Text("\(number)")
            .font(.tileNumber(size: side * 0.4))
            .foregroundStyle(Styleguide.tileLabel)
        }
      }
      .frame(width: side, height: side)
    }
    .buttonStyle(.plain)
    .disabled(tile == .empty)
  }
}

extension AchievementKey {
  fileprivate var title: String {
    switch self {
    case .firstWin: "First Win"
    case .speedy: "Speedy (under 1:00)"
    case .efficient: "No Hints"
    case .dailyDevotee: "Daily Devotee"
    case .bigBoard: "Big Board (5×5)"
    }
  }
}

#Preview {
  NavigationStack {
    GameView(
      store: Store(initialState: Game.State(boardSize: 4)) {
        Game()
      }
    )
  }
}
