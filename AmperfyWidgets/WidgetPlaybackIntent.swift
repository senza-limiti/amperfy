// SPDX-License-Identifier: GPL-3.0-or-later
import AppIntents
import Foundation

enum WidgetPlaybackAction: String, AppEnum {
  case toggle, next, previous, playItem
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Playback")
  static let caseDisplayRepresentations: [WidgetPlaybackAction: DisplayRepresentation] = [
    .toggle: "Play or pause", .next: "Next track", .previous: "Previous track",
    .playItem: "Play album or track",
  ]
}

enum WidgetPlaybackError: Error, LocalizedError {
  case openAppFirst, itemUnavailable, appProcessRequired
  var errorDescription: String? {
    switch self {
    case .openAppFirst: return "Open Amperfy and finish signing in first."
    case .itemUnavailable: return "This item is no longer available in the active account."
    case .appProcessRequired: return "Playback must run in the Amperfy app."
    }
  }
}

// AudioPlaybackIntent executes inside the main app, even when a widget button
// is tapped. The extension must never open a second player or Core Data store.
struct WidgetPlaybackIntent: AudioPlaybackIntent {
  static let title: LocalizedStringResource = "Amperfy Playback"
  static let description = IntentDescription("Control Amperfy from your Home Screen.")
  static let openAppWhenRun = false
  static let isDiscoverable = false

  @Parameter(title: "Action", default: .toggle)
  var action: WidgetPlaybackAction

  @Parameter(title: "Item", default: "")
  var itemID: String

  init() {}
  init(action: WidgetPlaybackAction, itemID: String = "") {
    self.action = action
    self.itemID = itemID
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    #if AMPERFY_WIDGET_EXTENSION
      throw WidgetPlaybackError.appProcessRequired
    #else
      appDelegate.widgetPublisher.start()
      try appDelegate.widgetPublisher.perform(action, itemID: itemID)
    #endif
    return .result()
  }
}
