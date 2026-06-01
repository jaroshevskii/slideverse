import DependenciesMacros

/// A controllable seam for playing the game's sound effects.
@DependencyClient
public struct AudioPlayerClient: Sendable {
  public var play: @Sendable (Sound) async -> Void

  public enum Sound: Equatable, Sendable {
    case tileMoved
    case victory
  }
}
