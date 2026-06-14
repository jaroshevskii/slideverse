//
//  SlideverseApp.swift
//  Slideverse
//
//  Created by Sasha Jaroshevskii on 31.05.2026.
//

import AppFeature
import ComposableArchitecture
import Models
import PuzzleSolverLive
import SwiftUI

@main
struct SlideverseApp: App {
  @MainActor
  static let store = Store(initialState: AppReducer.State()) {
    AppReducer()
  }

  init() {
    prepareDependencies {
      try! $0.bootstrapDatabase()
      // The interface module only ships `testValue`; register the live C++ solver so the
      // shipping app resolves it instead of the no-op test value.
      $0.puzzleSolver = .liveValue
    }
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: Self.store)
    }
  }
}
