import Dependencies

extension PuzzleSolverClient: DependencyKey {
  public static let liveValue = Self(
    solve: { board in
      // The IDA* search is CPU-bound; run it off the cooperative pool's main paths.
      await Task.detached(priority: .userInitiated) {
        PuzzleSolver.solution(for: board)
      }.value
    }
  )
}
