import Dependencies

#if canImport(AudioToolbox)
  import AudioToolbox
#endif

extension AudioPlayerClient: DependencyKey {
  public static let liveValue = Self(
    play: { sound in
      #if canImport(AudioToolbox)
        AudioServicesPlaySystemSound(sound.systemSoundID)
      #endif
    }
  )
}

#if canImport(AudioToolbox)
  extension AudioPlayerClient.Sound {
    /// A built-in system sound ID, so the game ships with audio and no bundled media.
    fileprivate var systemSoundID: SystemSoundID {
      switch self {
      case .tileMoved: 1104  // "Tock" — a short, crisp tap.
      case .victory: 1025  // A brighter, celebratory chime.
      }
    }
  }
#endif
