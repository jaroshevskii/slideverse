#pragma once

namespace slideverse {

/// Computes an optimal sequence of moves that solves a sliding puzzle.
///
/// - Parameters:
///   - tiles: The board in row-major order. `0` is the empty space and `1...count-1`
///     are the numbered tiles.
///   - count: The number of tiles (`size * size`).
///   - size: The board width `n`.
///   - outMoves: A caller-provided buffer that receives the tile indices to tap.
///   - maxMoves: The capacity of `outMoves`.
/// - Returns: The number of moves written (0 if already solved), or `-1` if no solution
///   was found within the search budget or the solution did not fit in `outMoves`.
int solve(const int *tiles, int count, int size, int *outMoves, int maxMoves);

}  // namespace slideverse
