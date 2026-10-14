// SPDX-License-Identifier: GPL-3.0-or-later
import AmperfyKit
import Foundation
import ImageIO
import os.log
import UIKit
import WidgetKit

@MainActor
final class WidgetPlaybackPublisher: NSObject, MusicPlayable {
  private var snapshot = WidgetSnapshotStore.read()
  private var started = false

  func start() {
    guard !started else { return }
    started = true
    appDelegate.player.addNotifier(notifier: self)
    NotificationCenter.default.addObserver(
      self, selector: #selector(accountChanged), name: .accountActiveChanged, object: nil
    )
    NotificationCenter.default.addObserver(
      self, selector: #selector(accountChanged), name: .accountDeleted, object: nil
    )
    publish(force: true)
  }

  @objc private func accountChanged() { publish(force: true) }

  private func thumbnail(path: String?) -> Data? {
    guard let path,
          let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 400,
            kCGImageSourceCreateThumbnailWithTransform: true,
          ] as CFDictionary)
    else { return nil }
    return UIImage(cgImage: image).jpegData(compressionQuality: 0.8)
  }

  private func track(_ playable: AbstractPlayable) -> WidgetTrack? {
    guard let accountID = playable.account?.info.ident else { return nil }
    let preference = appDelegate.storage.settings.accounts.getSetting(playable.account?.info)
      .read.artworkDisplayPreference
    let radio = appDelegate.player.currentRadioNowPlaying
    return WidgetTrack(
      id: playable.objectID.uriRepresentation().absoluteString,
      serverID: playable.id, accountID: accountID, kind: kind(playable),
      title: playable.isRadio && radio?.isEmpty == false ? radio!.title : playable.title,
      artist: playable.isRadio && radio?.isEmpty == false ? radio!.artist : playable.creatorName,
      artwork: thumbnail(path: playable.imagePath(setting: preference))
    )
  }

  private func recentItem(_ playable: AbstractPlayable, track: WidgetTrack) -> WidgetTrack {
    guard let album = playable.asSong?.album else { return track }
    return WidgetTrack(
      id: album.objectID.uriRepresentation().absoluteString,
      serverID: album.id, accountID: track.accountID, kind: "album",
      title: album.name, artist: album.artist?.name ?? track.artist, artwork: track.artwork
    )
  }

  private func kind(_ playable: AbstractPlayable) -> String {
    switch playable.derivedType {
    case .song: return "song"
    case .podcastEpisode: return "podcastEpisode"
    case .radio: return "radio"
    }
  }

  func publish(recordPlay: Bool = false, force: Bool = false) {
    let player = appDelegate.player
    let playable = player.currentlyPlaying
    let current = playable.flatMap { track($0) }
    let recent = playable.flatMap { item in current.map { recentItem(item, track: $0) } }
    let updated = snapshot.updating(
      accountID: appDelegate.storage.settings.accounts.active?.ident,
      current: current, recentItem: recent, isPlaying: player.isPlaying,
      canSkip: player.isSkipAvailable, recordPlay: recordPlay
    )
    guard force || snapshot != updated else { return }
    do {
      try WidgetSnapshotStore.write(updated)
      snapshot = updated
      WidgetCenter.shared.reloadTimelines(ofKind: "AmperfyNowPlaying")
      WidgetCenter.shared.reloadTimelines(ofKind: "AmperfyRecentlyPlayed")
    } catch {
      os_log("Widget snapshot could not be saved: %@", log: appDelegate.log,
             type: .error, error.localizedDescription)
    }
  }

  func didStartPlayingFromBeginning() { publish(recordPlay: true) }
  func didStartPlaying() { publish(recordPlay: true) }
  func didPause() { publish() }
  func didStopPlaying() { publish() }
  func didPlaylistChange() { publish() }
  func didArtworkChange() { publish() }
  func didNowPlayingInfoChange() { publish() }
  func didElapsedTimeChange() {}
  func didShuffleChange() {}
  func didRepeatChange() {}
  func didPlaybackRateChange() {}

  func perform(_ action: WidgetPlaybackAction, itemID: String) throws {
    guard appDelegate.isNormalInteraction else { throw WidgetPlaybackError.openAppFirst }
    let player = appDelegate.player
    switch action {
    case .toggle:
      if player.isStopInsteadOfPause && player.isPlaying { player.stop() }
      else { player.togglePlayPause() }
    case .next:
      if player.isSkipAvailable { player.playNext() }
    case .previous:
      if player.isSkipAvailable { player.playPreviousOrReplay() }
    case .playItem:
      guard let accountInfo = appDelegate.storage.settings.accounts.active,
            let item = snapshot.recent.first(where: { $0.id == itemID }),
            item.accountID == accountInfo.ident
      else { throw WidgetPlaybackError.itemUnavailable }
      let library = appDelegate.storage.main.library
      let account = library.getAccount(info: accountInfo)
      let context: PlayContext?
      switch item.kind {
      case "album":
        context = library.getAlbum(for: account, id: item.serverID, isDetailFaultResolution: true)
          .map { PlayContext(containable: $0) }
      case "song":
        context = library.getSong(for: account, id: item.serverID)
          .map { PlayContext(name: $0.title, playables: [$0]) }
      case "podcastEpisode":
        context = library.getPodcastEpisode(for: account, id: item.serverID)
          .map { PlayContext(name: $0.title, type: .podcast, playables: [$0]) }
      case "radio":
        context = library.getRadio(for: account, id: item.serverID)
          .map { PlayContext(name: $0.title, playables: [$0]) }
      default: context = nil
      }
      guard let context else { throw WidgetPlaybackError.itemUnavailable }
      player.play(context: context)
    }
    publish()
  }
}
