import Foundation
import Sharing

/// User-tunable preferences, persisted to a JSON file and shared app-wide via
/// `@Shared(.userSettings)`.
public struct UserSettings: Codable, Equatable, Sendable {
  public var appearance: Appearance
  public var soundEnabled: Bool
  public var hapticsEnabled: Bool
  public var defaultBoardSize: Int

  public init(
    appearance: Appearance = .system,
    soundEnabled: Bool = true,
    hapticsEnabled: Bool = true,
    defaultBoardSize: Int = 4
  ) {
    self.appearance = appearance
    self.soundEnabled = soundEnabled
    self.hapticsEnabled = hapticsEnabled
    self.defaultBoardSize = defaultBoardSize
  }
}

/// The user's preferred color scheme. Mapped to a SwiftUI `ColorScheme?` in the view layer.
public enum Appearance: String, Codable, CaseIterable, Sendable {
  case system
  case light
  case dark
}

extension SharedKey where Self == FileStorageKey<UserSettings>.Default {
  /// The shared, file-persisted user settings.
  public static var userSettings: Self {
    Self[
      .fileStorage(.applicationSupportDirectory.appending(component: "userSettings.json")),
      default: UserSettings()
    ]
  }
}
