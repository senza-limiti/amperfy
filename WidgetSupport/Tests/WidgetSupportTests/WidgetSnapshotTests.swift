// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import XCTest
@testable import WidgetSupport

final class WidgetSnapshotTests: XCTestCase {
  func track(_ id: String, account: String = "a", artwork: Data? = nil) -> WidgetTrack {
    WidgetTrack(id: id, serverID: id, accountID: account, kind: "album",
                title: "夜に駆ける", artist: "YOASOBI", artwork: artwork)
  }

  func testHistoryDeduplicatesAlbumsAndCapsSize() {
    var state = WidgetSnapshot.empty
    for index in 0 ..< 12 {
      let item = track(String(index))
      state = state.updating(accountID: "a", current: item, recentItem: item,
                             isPlaying: true, canSkip: true, recordPlay: true)
    }
    state = state.updating(accountID: "a", current: track("8"), recentItem: track("8"),
                           isPlaying: true, canSkip: true, recordPlay: true)
    XCTAssertEqual(state.recent.map(\.id), ["8", "11", "10", "9", "7", "6", "5", "4", "3"])
  }

  func testLateArtworkAndPauseDoNotReorderHistory() {
    let original = WidgetSnapshot(accountID: "a", current: track("2"),
                                  recent: [track("2"), track("1")], isPlaying: true)
    let updated = original.updating(accountID: "a", current: track("2"),
                                    recentItem: track("1", artwork: Data([1, 2])),
                                    isPlaying: false, canSkip: true, recordPlay: false)
    XCTAssertEqual(updated.recent.map(\.id), ["2", "1"])
    XCTAssertEqual(updated.recent.last?.artwork, Data([1, 2]))
    XCTAssertFalse(updated.isPlaying)
  }

  func testAccountChangesAndLogoutCannotExposeOtherAccount() {
    let original = WidgetSnapshot(accountID: "a", current: track("1"), recent: [track("1")])
    let switched = original.updating(accountID: "b", current: track("1"), recentItem: track("1"),
                                     isPlaying: true, canSkip: true, recordPlay: true)
    XCTAssertNil(switched.current)
    XCTAssertTrue(switched.recent.isEmpty)
    XCTAssertFalse(switched.isPlaying)
    XCTAssertEqual(original.updating(accountID: nil, current: track("1"), recentItem: nil,
                                     isPlaying: true, canSkip: true, recordPlay: false), .empty)
  }

  func testSideloadGroupRemappingIgnoresUnrelatedGroups() {
    let remapped = WidgetSnapshotStore.appGroup + ".ABC123"
    XCTAssertEqual(WidgetSnapshotStore.groupIdentifier(info: ["ALTAppGroups": ["group.other", remapped]]), remapped)
    XCTAssertEqual(WidgetSnapshotStore.groupIdentifier(info: [:]), WidgetSnapshotStore.appGroup)
  }

  func testAtomicSnapshotRoundTripAndCorruptFileFallback() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("snapshot.json")
    let state = WidgetSnapshot(accountID: "a", current: track("1", artwork: Data([0, 1, 255])))
    try WidgetSnapshotStore.write(state, to: url)
    XCTAssertEqual(WidgetSnapshotStore.read(from: url), state)
    try Data("invalid".utf8).write(to: url)
    XCTAssertEqual(WidgetSnapshotStore.read(from: url), .empty)
  }
}
