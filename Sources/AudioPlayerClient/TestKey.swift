import Dependencies

extension DependencyValues {
  public var audioPlayer: AudioPlayerClient {
    get { self[AudioPlayerClient.self] }
    set { self[AudioPlayerClient.self] = newValue }
  }
}

extension AudioPlayerClient: TestDependencyKey {
  public static let previewValue = Self.noop
  public static let testValue = Self()
}

extension AudioPlayerClient {
  /// A client that silently ignores every sound — handy for previews and tests.
  public static let noop = Self(play: { _ in })
}
