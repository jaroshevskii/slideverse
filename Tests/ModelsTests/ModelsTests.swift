import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Models

@Suite(
  .dependencies {
    $0.uuid = .incrementing
    $0.date = .constant(Date(timeIntervalSince1970: 1_700_000_000))
    try $0.bootstrapDatabase()
  }
)
struct ModelsTests {
  @Dependency(\.defaultDatabase) var database

  @Test func migrationsCreateTablesAndInsertsRoundTrip() throws {
    try database.write { db in
      try db.seed {
        CompletedGame(
          id: UUID(-1),
          boardSize: 4,
          moves: 42,
          seconds: 65,
          score: 1234,
          usedHint: false,
          mode: GameMode.classic.rawValue,
          completedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
      }
    }

    let games = try database.read { db in try CompletedGame.fetchAll(db) }
    #expect(games.count == 1)
    #expect(games.first?.score == 1234)
    #expect(games.first?.boardSize == 4)
  }

  @Test func achievementsInsertAndFetch() throws {
    try database.write { db in
      try db.seed {
        Achievement(id: UUID(-1), key: AchievementKey.firstWin.rawValue, unlockedAt: Date())
        Achievement(id: UUID(-2), key: AchievementKey.speedy.rawValue, unlockedAt: Date())
      }
    }
    let count = try database.read { db in try Achievement.fetchCount(db) }
    #expect(count == 2)
  }
}
