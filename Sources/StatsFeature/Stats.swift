import ComposableArchitecture
import Foundation
import Models
import SQLiteData
import SwiftUI

@Reducer
public struct Stats {
  @ObservableState
  public struct State: Equatable {
    @ObservationStateIgnored
    @FetchAll(CompletedGame.order { $0.completedAt.desc() }) public var games: [CompletedGame]
    @ObservationStateIgnored
    @FetchAll(Achievement.order { $0.unlockedAt.desc() }) public var achievements: [Achievement]

    public init() {}
  }

  public enum Action {}

  public init() {}

  public var body: some Reducer<State, Action> {
    EmptyReducer()
  }
}

public struct StatsView: View {
  let store: StoreOf<Stats>

  public init(store: StoreOf<Stats>) {
    self.store = store
  }

  public var body: some View {
    List {
      summarySection
      bestsSection
      achievementsSection
    }
    .navigationTitle("Stats")
  }

  private var summarySection: some View {
    Section {
      LabeledContent("Games played", value: "\(store.games.count)")
      LabeledContent("Best score", value: "\(store.games.map(\.score).max() ?? 0)")
      LabeledContent("Daily streak", value: "\(currentDailyStreak) days")
    }
  }

  private var bestsSection: some View {
    Section("Best times") {
      let bySize = Dictionary(grouping: store.games.filter { $0.mode == GameMode.classic.rawValue }) {
        $0.boardSize
      }
      if bySize.isEmpty {
        ContentUnavailableView("No games yet", systemImage: "square.grid.3x3")
      } else {
        ForEach(bySize.keys.sorted(), id: \.self) { size in
          let games = bySize[size] ?? []
          LabeledContent("\(size)×\(size)") {
            Text(timeString(games.map(\.seconds).min() ?? 0))
              .monospacedDigit()
          }
        }
      }
    }
  }

  private var achievementsSection: some View {
    Section("Achievements (\(store.achievements.count))") {
      ForEach(store.achievements) { achievement in
        if let key = AchievementKey(rawValue: achievement.key) {
          Label(key.title, systemImage: "rosette")
            .foregroundStyle(.orange)
        }
      }
    }
  }

  /// Number of consecutive days, ending today, with at least one completed game.
  private var currentDailyStreak: Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    let days = Set(store.games.map { calendar.startOfDay(for: $0.completedAt) })
    guard !days.isEmpty else { return 0 }
    var streak = 0
    var day = calendar.startOfDay(for: Date())
    while days.contains(day) {
      streak += 1
      guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
      day = previous
    }
    return streak
  }

  private func timeString(_ seconds: Int) -> String {
    String(format: "%02d:%02d", seconds / 60, seconds % 60)
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
