import SwiftUI

/// Shared visual constants for the puzzle UI. Echoes the original game's palette
/// (warm orange tiles, a dim empty cell) while leaning on system materials and fonts
/// so it feels at home on Apple platforms.
public enum Styleguide {
  /// Background fill for a numbered tile.
  public static let tile = Color.orange

  /// Foreground (number) color on a numbered tile.
  public static let tileLabel = Color.white

  /// Fill for the empty space.
  public static let emptyTile = Color(white: 0.2)

  /// Spacing between tiles in the grid.
  public static let tileSpacing: CGFloat = 6

  /// Corner radius applied to each tile.
  public static let tileCornerRadius: CGFloat = 12
}

extension Font {
  /// Monospaced-digit font for the timer and move counter so values don't jitter.
  public static func puzzleStat() -> Font {
    .system(.title3, design: .rounded).monospacedDigit().weight(.semibold)
  }

  /// Rounded, bold font for a tile's number, scaled to the available tile size.
  public static func tileNumber(size: CGFloat) -> Font {
    .system(size: size, weight: .bold, design: .rounded)
  }
}
