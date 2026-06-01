//
//  SlideverseApp.swift
//  Slideverse
//
//  Created by Sasha Jaroshevskii on 31.05.2026.
//

import AppFeature
import ComposableArchitecture
import Models
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
    }
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: Self.store)
    }
  }
}
