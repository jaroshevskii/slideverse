import Dependencies

extension DependencyValues {
  public var haptics: HapticsClient {
    get { self[HapticsClient.self] }
    set { self[HapticsClient.self] = newValue }
  }
}

extension HapticsClient: TestDependencyKey {
  public static let previewValue = Self.noop
  public static let testValue = Self()
}

extension HapticsClient {
  /// A client that produces no feedback — for previews and tests.
  public static let noop = Self(impact: { _ in }, notify: { _ in })
}
