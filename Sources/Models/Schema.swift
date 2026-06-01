import Dependencies
import Foundation
import SQLiteData

extension DependencyValues {
  /// Opens the on-device SQLite database, runs migrations, and installs it as the
  /// `defaultDatabase`. Call once from the app entry point inside `prepareDependencies`.
  public mutating func bootstrapDatabase() throws {
    let database = try SQLiteData.defaultDatabase()

    var migrator = DatabaseMigrator()
    #if DEBUG
      migrator.eraseDatabaseOnSchemaChange = true
    #endif
    migrator.registerMigration("Create 'completedGames' and 'achievements' tables") { db in
      try #sql(
        """
        CREATE TABLE "completedGames" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
          "boardSize" INTEGER NOT NULL DEFAULT 4,
          "moves" INTEGER NOT NULL DEFAULT 0,
          "seconds" INTEGER NOT NULL DEFAULT 0,
          "score" INTEGER NOT NULL DEFAULT 0,
          "usedHint" INTEGER NOT NULL DEFAULT 0,
          "mode" TEXT NOT NULL DEFAULT 'classic',
          "dayKey" TEXT,
          "completedAt" TEXT NOT NULL
        ) STRICT
        """
      )
      .execute(db)

      try #sql(
        """
        CREATE TABLE "achievements" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
          "key" TEXT NOT NULL,
          "unlockedAt" TEXT NOT NULL
        ) STRICT
        """
      )
      .execute(db)

      try #sql(
        """
        CREATE UNIQUE INDEX "index_achievements_on_key" ON "achievements"("key")
        """
      )
      .execute(db)

      try #sql(
        """
        CREATE INDEX "index_completedGames_on_boardSize"
          ON "completedGames"("boardSize")
        """
      )
      .execute(db)
    }
    try migrator.migrate(database)

    defaultDatabase = database
  }
}
