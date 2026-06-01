import Dependencies

#if canImport(UIKit)
  import UIKit

  extension HapticsClient: DependencyKey {
    public static let liveValue = Self(
      impact: { style in
        await MainActor.run {
          UIImpactFeedbackGenerator(style: style.uiStyle).impactOccurred()
        }
      },
      notify: { type in
        await MainActor.run {
          UINotificationFeedbackGenerator().notificationOccurred(type.uiType)
        }
      }
    )
  }

  extension HapticsClient.ImpactStyle {
    fileprivate var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
      switch self {
      case .light: .light
      case .medium: .medium
      case .heavy: .heavy
      case .rigid: .rigid
      case .soft: .soft
      }
    }
  }

  extension HapticsClient.NotificationType {
    fileprivate var uiType: UINotificationFeedbackGenerator.FeedbackType {
      switch self {
      case .success: .success
      case .warning: .warning
      case .error: .error
      }
    }
  }
#else
  extension HapticsClient: DependencyKey {
    public static let liveValue = Self.noop
  }
#endif
