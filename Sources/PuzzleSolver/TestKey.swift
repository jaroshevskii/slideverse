import Dependencies

extension DependencyValues {
  public var puzzleSolver: PuzzleSolverClient {
    get { self[PuzzleSolverClient.self] }
    set { self[PuzzleSolverClient.self] = newValue }
  }
}

extension PuzzleSolverClient: TestDependencyKey {
  public static let previewValue = Self.noop
  public static let testValue = Self()
}

extension PuzzleSolverClient {
  /// A solver that always reports "no moves" — useful for previews and tests.
  public static let noop = Self(solve: { _ in [] })
}
