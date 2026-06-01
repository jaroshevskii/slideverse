import AudioPlayerClient
import ComposableArchitecture
import Dependencies
import DependenciesTestSupport
import Foundation
import HapticsClient
import Models
import PuzzleCore
import PuzzleSolver
import Testing

@testable import GameFeature

@MainActor
@Suite(
  .dependencies {
    $0.uuid = .incrementing
    $0.date = .constant(Date(timeIntervalSince1970: 1_700_000_000))
    try $0.bootstrapDatabase()
  }
)
struct GameTests {
  /// Solved 4×4 with tile 12 slid down: empty at index 11. Tapping 15 wins; tapping 7 doesn't.
  private func nearWinState() -> Game.State {
    var board = Board.solved(size: 4)
    board.move(at: 11)
    var state = Game.State(boardSize: 4)
    state.board = board
    return state
  }

  @Test func nonWinningMoveRecordsHistory() async {
    let store = TestStore(initialState: nearWinState()) { Game() } withDependencies: {
      $0.audioPlayer = .noop
      $0.haptics = .noop
    }
    await store.send(.tileTapped(7)) {
      $0.board.move(at: 7)
      $0.moveCount = 1
      $0.moveHistory = [11]
    }
  }

  @Test func undoRestoresPreviousBoard() async {
    let store = TestStore(initialState: nearWinState()) { Game() } withDependencies: {
      $0.audioPlayer = .noop
      $0.haptics = .noop
    }
    await store.send(.tileTapped(7)) {
      $0.board.move(at: 7)
      $0.moveCount = 1
      $0.moveHistory = [11]
    }
    await store.send(.undoButtonTapped) {
      $0.board.move(at: 11)
      $0.moveCount = 0
      $0.moveHistory = []
    }
  }

  @Test func pauseCancelsTimer() async {
    let clock = TestClock()
    let store = TestStore(initialState: nearWinState()) { Game() } withDependencies: {
      $0.continuousClock = clock
      $0.audioPlayer = .noop
      $0.haptics = .noop
    }
    await store.send(.task)
    await clock.advance(by: .seconds(1))
    await store.receive(\.timerTicked) { $0.secondsElapsed = 1 }
    await store.send(.pauseButtonTapped) { $0.isPaused = true }
    // Timer is cancelled — advancing produces no further ticks.
    await clock.advance(by: .seconds(5))
  }

  @Test func hintHighlightsNextMove() async {
    let store = TestStore(initialState: nearWinState()) { Game() } withDependencies: {
      $0.audioPlayer = .noop
      $0.haptics = .noop
      $0.puzzleSolver.solve = { _ in [15] }
    }
    await store.send(.hintButtonTapped) {
      $0.isSolving = true
      $0.usedHint = true
    }
    await store.receive(\.hintResponse) {
      $0.isSolving = false
      $0.hintIndex = 15
    }
  }

  @Test func winningMovePersistsAndUnlocksAchievements() async {
    let store = TestStore(initialState: nearWinState()) { Game() } withDependencies: {
      $0.audioPlayer = .noop
      $0.haptics = .noop
    }
    await store.send(.tileTapped(15)) {
      $0.board.move(at: 15)
      $0.moveCount = 1
      $0.moveHistory = [11]
      $0.isGameOver = true
      $0.lastScore = 1595
    }
    await store.receive(\.gamePersisted) {
      $0.isNewBest = true
      $0.unlockedAchievements = [.firstWin, .speedy, .efficient]
      $0.confettiID = 1
    }
  }
}
