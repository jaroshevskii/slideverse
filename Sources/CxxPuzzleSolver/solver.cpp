#include "CxxPuzzleSolver.h"

#include <climits>
#include <cstdlib>
#include <utility>
#include <vector>

namespace slideverse {
namespace {

// IDA* search over the sliding-puzzle state space using an admissible heuristic
// (sum of Manhattan distances + linear conflicts), so the returned solution is optimal.
struct Solver {
  int n = 0;
  int count = 0;
  std::vector<int> goalRow;  // goalRow[v] / goalCol[v] = solved position of tile value v
  std::vector<int> goalCol;
  long long nodes = 0;
  long long nodeBudget = 30'000'000;
  std::vector<int> path;  // tapped tile indices accumulated along the current branch

  int heuristic(const std::vector<int> &t) const {
    int h = 0;
    for (int i = 0; i < count; ++i) {
      int v = t[i];
      if (v == 0) continue;
      int r = i / n, c = i % n;
      h += std::abs(r - goalRow[v]) + std::abs(c - goalCol[v]);
    }
    // Linear conflicts within goal rows.
    for (int r = 0; r < n; ++r) {
      for (int c1 = 0; c1 < n; ++c1) {
        int v1 = t[r * n + c1];
        if (v1 == 0 || goalRow[v1] != r) continue;
        for (int c2 = c1 + 1; c2 < n; ++c2) {
          int v2 = t[r * n + c2];
          if (v2 == 0 || goalRow[v2] != r) continue;
          if (goalCol[v1] > goalCol[v2]) h += 2;
        }
      }
    }
    // Linear conflicts within goal columns.
    for (int c = 0; c < n; ++c) {
      for (int r1 = 0; r1 < n; ++r1) {
        int v1 = t[r1 * n + c];
        if (v1 == 0 || goalCol[v1] != c) continue;
        for (int r2 = r1 + 1; r2 < n; ++r2) {
          int v2 = t[r2 * n + c];
          if (v2 == 0 || goalCol[v2] != c) continue;
          if (goalRow[v1] > goalRow[v2]) h += 2;
        }
      }
    }
    return h;
  }

  // Returns -1 when solved, -2 when the node budget is exceeded, otherwise the smallest
  // f-value that exceeded the current bound (for the next IDA* iteration).
  int dfs(std::vector<int> &t, int empty, int g, int bound, int prevEmpty) {
    int h = heuristic(t);
    int f = g + h;
    if (f > bound) return f;
    if (h == 0) return -1;
    if (++nodes > nodeBudget) return -2;

    int minExceed = INT_MAX;
    int r = empty / n, c = empty % n;
    static const int dr[4] = {-1, 1, 0, 0};
    static const int dc[4] = {0, 0, -1, 1};
    for (int d = 0; d < 4; ++d) {
      int nr = r + dr[d], nc = c + dc[d];
      if (nr < 0 || nr >= n || nc < 0 || nc >= n) continue;
      int np = nr * n + nc;
      if (np == prevEmpty) continue;  // never undo the previous move

      std::swap(t[empty], t[np]);
      path.push_back(np);
      int res = dfs(t, np, g + 1, bound, empty);
      std::swap(t[empty], t[np]);
      if (res == -1) return -1;
      if (res == -2) { path.pop_back(); return -2; }
      path.pop_back();
      if (res < minExceed) minExceed = res;
    }
    return minExceed;
  }
};

}  // namespace

int solve(const int *tiles, int count, int size, int *outMoves, int maxMoves) {
  Solver solver;
  solver.n = size;
  solver.count = count;
  solver.goalRow.assign(count, 0);
  solver.goalCol.assign(count, 0);
  for (int v = 1; v < count; ++v) {
    solver.goalRow[v] = (v - 1) / size;
    solver.goalCol[v] = (v - 1) % size;
  }

  std::vector<int> board(tiles, tiles + count);
  int empty = 0;
  for (int i = 0; i < count; ++i) {
    if (board[i] == 0) { empty = i; break; }
  }

  int bound = solver.heuristic(board);
  if (bound == 0) return 0;  // already solved

  while (true) {
    solver.path.clear();
    int res = solver.dfs(board, empty, 0, bound, -1);
    if (res == -1) break;
    if (res == -2 || res == INT_MAX) return -1;  // budget exceeded or no moves
    bound = res;
  }

  int produced = static_cast<int>(solver.path.size());
  if (produced > maxMoves) return -1;
  for (int i = 0; i < produced; ++i) outMoves[i] = solver.path[i];
  return produced;
}

}  // namespace slideverse
