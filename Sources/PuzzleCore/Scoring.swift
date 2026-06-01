extension Board {
  /// Scores a completed game. More tiles, fewer moves, and less time score higher; using
  /// a hint applies a flat penalty. Never returns a negative score.
  ///
  /// - Parameters:
  ///   - boardSize: The board width (3, 4, 5, …).
  ///   - moves: The number of moves taken.
  ///   - seconds: The elapsed time in seconds.
  ///   - usedHint: Whether the player asked for a hint or auto-solve.
  public static func score(
    boardSize: Int,
    moves: Int,
    seconds: Int,
    usedHint: Bool
  ) -> Int {
    let base = boardSize * boardSize * 100
    let movePenalty = moves * 5
    let timePenalty = seconds * 2
    let hintPenalty = usedHint ? base / 2 : 0
    return max(0, base - movePenalty - timePenalty - hintPenalty)
  }
}
