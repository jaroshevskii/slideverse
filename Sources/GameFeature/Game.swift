import AudioPlayerClient
import ComposableArchitecture
import Foundation
import HapticsClient
import Models
import PuzzleCore
import PuzzleSolver
import Settings
import SQLiteData

@Reducer
public struct Game {
  @ObservableState
  public struct State: Equatable {
    public var board: Board
    public var boardSize: Int
    public var mode: GameMode
    public var dayKey: String?

    public var moveCount: Int
    public var secondsElapsed: Int
    public var moveHistory: [Int]   // pre-move empty indices, used to undo

    public var isGameOver: Bool
    public var isPaused: Bool
    public var isSolving: Bool       // computing a hint
    public var isAutoSolving: Bool
    public var hintIndex: Int?
    public var usedHint: Bool
    var autoSolveMoves: [Int]

    // Result, populated as the winning game is scored and persisted.
    public var lastScore: Int
    public var isNewBest: Bool
    public var unlockedAchievements: [AchievementKey]
    public var confettiID: Int

    @ObservationStateIgnored
    @Shared(.userSettings) public var settings: UserSettings

    public var canUseSolver: Bool { boardSize <= 4 }
    public var canUndo: Bool { !moveHistory.isEmpty && !isGameOver && !isAutoSolving }

    public init(boardSize: Int = 4, mode: GameMode = .classic) {
      self.board = .solved(size: boardSize)
      self.boardSize = boardSize
      self.mode = mode
      self.moveCount = 0
      self.secondsElapsed = 0
      self.moveHistory = []
      self.isGameOver = false
      self.isPaused = false
      self.isSolving = false
      self.isAutoSolving = false
      self.usedHint = false
      self.autoSolveMoves = []
      self.lastScore = 0
      self.isNewBest = false
      self.unlockedAchievements = []
      self.confettiID = 0
    }
  }

  public enum Action {
    case autoSolveButtonTapped
    case autoSolveResponse([Int])
    case autoSolveStepTicked
    case boardSizeChanged(Int)
    case gamePersisted(isNewBest: Bool, achievements: [AchievementKey])
    case hintButtonTapped
    case hintResponse([Int])
    case newGameButtonTapped
    case pauseButtonTapped
    case task
    case tileTapped(Int)
    case timerTicked
    case undoButtonTapped
  }

  enum CancelID { case timer, autoSolve }

  @Dependency(\.audioPlayer) var audioPlayer
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date) var date
  @Dependency(\.defaultDatabase) var database
  @Dependency(\.haptics) var haptics
  @Dependency(\.puzzleSolver) var puzzleSolver
  @Dependency(\.uuid) var uuid
  @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator

  public init() {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .autoSolveButtonTapped:
        guard !state.isGameOver, !state.isAutoSolving, state.canUseSolver else { return .none }
        state.isAutoSolving = true
        state.usedHint = true
        state.hintIndex = nil
        let board = state.board
        let puzzleSolver = self.puzzleSolver
        return .run { send in
          await send(.autoSolveResponse(puzzleSolver.solve(board)))
        }

      case let .autoSolveResponse(moves):
        guard state.isAutoSolving, !moves.isEmpty else {
          state.isAutoSolving = false
          return .none
        }
        state.autoSolveMoves = moves
        return autoSolveTimer()

      case .autoSolveStepTicked:
        guard !state.autoSolveMoves.isEmpty else {
          state.isAutoSolving = false
          return .cancel(id: CancelID.autoSolve)
        }
        let index = state.autoSolveMoves.removeFirst()
        state.board.move(at: index)
        state.moveCount += 1
        if state.board.isSolved {
          return .merge(.cancel(id: CancelID.autoSolve), handleWin(&state))
        }
        return .none

      case let .boardSizeChanged(size):
        guard size != state.boardSize else { return .none }
        state.boardSize = size
        return startNewGame(&state)

      case let .gamePersisted(isNewBest, achievements):
        state.isNewBest = isNewBest
        state.unlockedAchievements = achievements
        state.confettiID += 1
        return .none

      case .hintButtonTapped:
        guard !state.isGameOver, !state.isAutoSolving, !state.isSolving, state.canUseSolver
        else { return .none }
        state.isSolving = true
        state.usedHint = true
        let board = state.board
        let puzzleSolver = self.puzzleSolver
        return .run { send in
          await send(.hintResponse(puzzleSolver.solve(board)))
        }

      case let .hintResponse(moves):
        state.isSolving = false
        state.hintIndex = moves.first
        return .none

      case .newGameButtonTapped:
        return startNewGame(&state)

      case .pauseButtonTapped:
        guard !state.isGameOver else { return .none }
        state.isPaused.toggle()
        return state.isPaused ? .cancel(id: CancelID.timer) : startTimer()

      case .task:
        if state.board.isSolved {
          state.board = makeBoard(&state)
        }
        return startTimer()

      case let .tileTapped(index):
        guard !state.isGameOver, !state.isPaused, !state.isAutoSolving else { return .none }
        let emptyBefore = state.board.emptyIndex
        guard state.board.move(at: index) else { return .none }
        state.moveHistory.append(emptyBefore)
        state.moveCount += 1
        state.hintIndex = nil
        if state.board.isSolved {
          return handleWin(&state)
        }
        return feedback(state, sound: .tileMoved, impact: .light)

      case .timerTicked:
        state.secondsElapsed += 1
        return .none

      case .undoButtonTapped:
        guard state.canUndo, let previousEmpty = state.moveHistory.popLast() else { return .none }
        state.board.move(at: previousEmpty)
        state.moveCount = max(0, state.moveCount - 1)
        state.hintIndex = nil
        return feedback(state, sound: .tileMoved, impact: .soft)
      }
    }
  }

  // MARK: - Helpers

  private func startNewGame(_ state: inout State) -> Effect<Action> {
    state.board = makeBoard(&state)
    state.moveCount = 0
    state.secondsElapsed = 0
    state.moveHistory = []
    state.isGameOver = false
    state.isPaused = false
    state.isSolving = false
    state.isAutoSolving = false
    state.hintIndex = nil
    state.usedHint = false
    state.autoSolveMoves = []
    state.lastScore = 0
    state.isNewBest = false
    state.unlockedAchievements = []
    return .merge(.cancel(id: CancelID.autoSolve), startTimer())
  }

  private func makeBoard(_ state: inout State) -> Board {
    let size = state.boardSize
    let moves = scrambleMoves(size)
    switch state.mode {
    case .classic:
      return withRandomNumberGenerator {
        Board.scrambled(size: size, moves: moves, using: &$0)
      }
    case .daily:
      let key = dayKey(date.now)
      state.dayKey = key
      var rng = SeededRandomNumberGenerator(seed: seed(from: key))
      return Board.scrambled(size: size, moves: moves, using: &rng)
    }
  }

  private func handleWin(_ state: inout State) -> Effect<Action> {
    state.isGameOver = true
    state.isPaused = false
    state.isAutoSolving = false
    state.hintIndex = nil
    let score = Board.score(
      boardSize: state.boardSize,
      moves: state.moveCount,
      seconds: state.secondsElapsed,
      usedHint: state.usedHint
    )
    state.lastScore = score

    let soundOn = state.settings.soundEnabled
    let hapticsOn = state.settings.hapticsEnabled
    let game = CompletedGame(
      id: uuid(),
      boardSize: state.boardSize,
      moves: state.moveCount,
      seconds: state.secondsElapsed,
      score: score,
      usedHint: state.usedHint,
      mode: state.mode.rawValue,
      dayKey: state.dayKey,
      completedAt: date.now
    )
    let database = self.database
    let uuid = self.uuid
    let now = date.now
    let audioPlayer = self.audioPlayer
    let haptics = self.haptics

    return .merge(
      .cancel(id: CancelID.timer),
      .cancel(id: CancelID.autoSolve),
      soundOn ? .run { _ in await audioPlayer.play(.victory) } : .none,
      hapticsOn ? .run { _ in await haptics.notify(.success) } : .none,
      .run { send in
        let outcome = persistResult(game, database: database, uuid: uuid, now: now)
        await send(
          .gamePersisted(isNewBest: outcome.isNewBest, achievements: outcome.unlocked),
          animation: .bouncy
        )
      }
    )
  }

  private func feedback(
    _ state: State,
    sound: AudioPlayerClient.Sound,
    impact: HapticsClient.ImpactStyle
  ) -> Effect<Action> {
    let audioPlayer = self.audioPlayer
    let haptics = self.haptics
    return .merge(
      state.settings.soundEnabled ? .run { _ in await audioPlayer.play(sound) } : .none,
      state.settings.hapticsEnabled ? .run { _ in await haptics.impact(impact) } : .none
    )
  }

  private func startTimer() -> Effect<Action> {
    let clock = self.clock
    return .run { send in
      for await _ in clock.timer(interval: .seconds(1)) {
        await send(.timerTicked)
      }
    }
    .cancellable(id: CancelID.timer, cancelInFlight: true)
  }

  private func autoSolveTimer() -> Effect<Action> {
    let clock = self.clock
    return .run { send in
      for await _ in clock.timer(interval: .milliseconds(220)) {
        await send(.autoSolveStepTicked, animation: .snappy)
      }
    }
    .cancellable(id: CancelID.autoSolve, cancelInFlight: true)
  }
}

private func scrambleMoves(_ size: Int) -> Int { size * size * 2 + 20 }

private func dayKey(_ date: Date) -> String {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
  let components = calendar.dateComponents([.year, .month, .day], from: date)
  return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
}

private func seed(from key: String) -> UInt64 {
  var hash: UInt64 = 0xcbf2_9ce4_8422_2325  // FNV-1a
  for byte in key.utf8 {
    hash ^= UInt64(byte)
    hash = hash &* 0x0000_0100_0000_01b3
  }
  return hash
}

/// Records a finished game, unlocks any newly earned achievements, and reports whether the
/// score is a new personal best. Pure with respect to the reducer (no captured `self`).
private func persistResult(
  _ game: CompletedGame,
  database: any DatabaseWriter,
  uuid: UUIDGenerator,
  now: Date
) -> (isNewBest: Bool, unlocked: [AchievementKey]) {
  var isNewBest = false
  var unlocked: [AchievementKey] = []

  withErrorReporting {
    let previousScores = try database.read { db in
      try CompletedGame
        .where { $0.boardSize.eq(game.boardSize) && $0.mode.eq(GameMode.classic.rawValue) }
        .select(\.score)
        .fetchAll(db)
    }
    isNewBest = game.mode == GameMode.classic.rawValue && game.score > (previousScores.max() ?? -1)

    try database.write { db in
      try CompletedGame.insert { game }.execute(db)
    }

    let existing = Set(
      try database.read { db in try Achievement.select(\.key).fetchAll(db) }
    )
    var earned: [AchievementKey] = [.firstWin]
    if game.seconds < 60 { earned.append(.speedy) }
    if !game.usedHint { earned.append(.efficient) }
    if game.mode == GameMode.daily.rawValue { earned.append(.dailyDevotee) }
    if game.boardSize >= 5 { earned.append(.bigBoard) }

    for key in earned where !existing.contains(key.rawValue) {
      try database.write { db in
        try Achievement.insert {
          Achievement(id: uuid(), key: key.rawValue, unlockedAt: now)
        }
        .execute(db)
      }
      unlocked.append(key)
    }
  }

  return (isNewBest, unlocked)
}
