// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

struct WidgetTrack: Codable, Equatable, Identifiable, Sendable {
  let id: String
  let serverID: String
  let accountID: String
  let kind: String
  let title: String
  let artist: String
  let artwork: Data?
}

struct WidgetSnapshot: Codable, Equatable, Sendable {
  var accountID: String?
  var current: WidgetTrack?
  var recent: [WidgetTrack] = []
  var isPlaying = false
  var canSkip = false

  static let empty = WidgetSnapshot()

  func updating(
    accountID: String?, current: WidgetTrack?, recentItem: WidgetTrack?,
    isPlaying: Bool, canSkip: Bool, recordPlay: Bool
  ) -> WidgetSnapshot {
    guard let accountID else { return .empty }
    let current = current?.accountID == accountID ? current : nil
    var items = recent.filter { $0.accountID == accountID }
    if let recentItem, recentItem.accountID == accountID {
      if recordPlay {
        items.removeAll { $0.id == recentItem.id }
        items.insert(recentItem, at: 0)
      } else if let index = items.firstIndex(where: { $0.id == recentItem.id }) {
        // Artwork can arrive after playback starts; update without reordering history.
        items[index] = recentItem
      }
    }
    return WidgetSnapshot(
      accountID: accountID, current: current, recent: Array(items.prefix(9)),
      isPlaying: current != nil && isPlaying, canSkip: current != nil && canSkip
    )
  }
}

enum WidgetSnapshotStore {
  static let appGroup = "group.de.familie-zimba.amperfy-music.widgets"

  static func groupIdentifier(info: [String: Any]) -> String {
    // AltStore and SideStore rewrite entitlements and expose the signed group
    // names in ALTAppGroups. Never assume the upstream developer's group survived.
    let groups = info["ALTAppGroups"] as? [String] ?? []
    return groups.first { $0 == appGroup || $0.hasPrefix(appGroup + ".") } ?? appGroup
  }

  static var fileURL: URL? {
    #if os(iOS)
      let group = groupIdentifier(info: Bundle.main.infoDictionary ?? [:])
      return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
        .appendingPathComponent("music-widget.json")
    #else
      return nil
    #endif
  }

  static func read(from url: URL? = fileURL) -> WidgetSnapshot {
    guard let url, let data = try? Data(contentsOf: url),
          let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    else { return .empty }
    return snapshot
  }

  static func write(_ snapshot: WidgetSnapshot, to url: URL? = fileURL) throws {
    guard let url else { throw CocoaError(.fileNoSuchFile) }
    try JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
  }
}
