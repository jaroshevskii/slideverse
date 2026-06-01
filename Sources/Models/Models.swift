import Foundation
import SQLiteData

/// A finished game, persisted so we can compute stats, best times, and high scores.
@Table
public struct CompletedGame: Identifiable, Equatable, Sendable {
  public let id: UUID
  public var boardSize: Int
  public var moves: Int
  public var seconds: Int
  public var score: Int
  public var usedHint: Bool
  public var mode: String
  public var dayKey: String?
  public var completedAt: Date

  public init(
    id: UUID,
    boardSize: Int,
    moves: Int,
    seconds: Int,
    score: Int,
    usedHint: Bool,
    mode: String,
    dayKey: String? = nil,
    completedAt: Date
  ) {
    self.id = id
    self.boardSize = boardSize
    self.moves = moves
    self.seconds = seconds
    self.score = score
    self.usedHint = usedHint
    self.mode = mode
    self.dayKey = dayKey
    self.completedAt = completedAt
  }
}

/// An unlocked achievement, keyed by a stable identifier (see ``AchievementKey``).
@Table
public struct Achievement: Identifiable, Equatable, Sendable {
  public let id: UUID
  public var key: String
  public var unlockedAt: Date

  public init(id: UUID, key: String, unlockedAt: Date) {
    self.id = id
    self.key = key
    self.unlockedAt = unlockedAt
  }
}

/// The mode a game was played in.
public enum GameMode: String, Equatable, Sendable {
  case classic
  case daily
}

/// Stable identifiers for the achievements the game can unlock.
public enum AchievementKey: String, CaseIterable, Sendable {
  case firstWin
  case speedy          // solved under 60 seconds
  case efficient       // solved without a hint
  case dailyDevotee    // completed a daily challenge
  case bigBoard        // solved a 5×5
}
