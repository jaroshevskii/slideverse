import DependenciesMacros

/// A controllable seam for tactile feedback.
@DependencyClient
public struct HapticsClient: Sendable {
  public var impact: @Sendable (ImpactStyle) async -> Void
  public var notify: @Sendable (NotificationType) async -> Void

  public enum ImpactStyle: Equatable, Sendable {
    case light, medium, heavy, rigid, soft
  }

  public enum NotificationType: Equatable, Sendable {
    case success, warning, error
  }
}
