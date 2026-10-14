// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UIKit
import WidgetKit

struct MusicEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
}

struct MusicProvider: TimelineProvider {
  func placeholder(in context: Context) -> MusicEntry {
    MusicEntry(date: .now, snapshot: MusicPreview.snapshot)
  }

  func getSnapshot(in context: Context, completion: @escaping (MusicEntry) -> Void) {
    completion(MusicEntry(date: .now,
                          snapshot: context.isPreview ? MusicPreview.snapshot : WidgetSnapshotStore.read()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<MusicEntry>) -> Void) {
    // Playback callbacks request updates. No polling, networking, or duplicate player.
    completion(Timeline(entries: [MusicEntry(date: .now, snapshot: WidgetSnapshotStore.read())], policy: .never))
  }
}

private let musicPink = Color(red: 1, green: 0.18, blue: 0.34)
private let musicGradient = LinearGradient(
  colors: [Color(red: 1, green: 0.36, blue: 0.47), musicPink],
  startPoint: .top, endPoint: .bottom
)

struct CoverArtwork: View {
  let track: WidgetTrack?
  var cornerRadius: CGFloat = 8

  var body: some View {
    GeometryReader { geometry in
      Group {
        if let data = track?.artwork, let image = UIImage(data: data) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .widgetAccentedRenderingMode(.fullColor)
        } else {
          ZStack {
            LinearGradient(colors: [.white.opacity(0.24), .white.opacity(0.06)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "music.note")
              .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.36, weight: .medium))
              .foregroundStyle(.white.opacity(0.8))
          }
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .clipped()
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    .accessibilityHidden(true)
  }
}

struct PlaybackButton: View {
  let action: WidgetPlaybackAction
  let symbol: String
  let label: String
  var size: CGFloat = 17
  var circular = false
  var itemID = ""

  var body: some View {
    Button(intent: WidgetPlaybackIntent(action: action, itemID: itemID)) {
      Image(systemName: symbol)
        .font(.system(size: size, weight: .semibold))
        .frame(width: circular ? 36 : 44, height: 36)
        .background(circular ? Color.white.opacity(0.22) : .clear, in: Circle())
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }
}

struct PlaybackControls: View {
  let snapshot: WidgetSnapshot

  var body: some View {
    HStack(spacing: 12) {
      PlaybackButton(action: .previous, symbol: "backward.fill", label: "Previous track")
        .disabled(!snapshot.canSkip)
        .opacity(snapshot.canSkip ? 1 : 0.35)
      PlaybackButton(action: .toggle, symbol: snapshot.isPlaying ? "pause.fill" : "play.fill",
                     label: snapshot.isPlaying ? "Pause" : "Play", size: 23)
      PlaybackButton(action: .next, symbol: "forward.fill", label: "Next track")
        .disabled(!snapshot.canSkip)
        .opacity(snapshot.canSkip ? 1 : 0.35)
    }
  }
}

struct NowPlayingView: View {
  let entry: MusicEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    content
      .foregroundStyle(.white)
      .containerBackground(for: .widget) { backdrop }
      .widgetURL(URL(string: "amperfy-widgets://"))
  }

  var content: some View {
    Group {
      if entry.snapshot.current == nil {
        MusicEmptyView(title: "Now Playing")
      } else if family == .systemMedium {
        medium
      } else {
        artworkLayout
      }
    }
  }

  var backdrop: some View {
    ZStack {
      if family == .systemMedium || entry.snapshot.current == nil {
        musicGradient
      } else {
        CoverArtwork(track: entry.snapshot.current, cornerRadius: 0)
        LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.12), .black.opacity(0.85)],
                       startPoint: .top, endPoint: .bottom)
      }
    }
  }

  private var medium: some View {
    GeometryReader { geometry in
      HStack(spacing: 16) {
        CoverArtwork(track: entry.snapshot.current)
          .frame(width: min(geometry.size.height - 32, 112), height: min(geometry.size.height - 32, 112))
          .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("NOW PLAYING").font(.system(size: 9, weight: .semibold)).opacity(0.8)
            Spacer(minLength: 0)
            Image(systemName: "music.note").font(.system(size: 17, weight: .bold))
          }
          Spacer(minLength: 0)
          Text(entry.snapshot.current?.title ?? "Amperfy")
            .font(.system(size: 17, weight: .semibold)).lineLimit(1)
          Text(entry.snapshot.current?.artist ?? "")
            .font(.system(size: 14)).opacity(0.8).lineLimit(1)
          Spacer(minLength: 0)
          PlaybackControls(snapshot: entry.snapshot)
            .frame(maxWidth: .infinity)
        }
      }
      .padding(16)
    }
  }

  private var artworkLayout: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        if family == .systemLarge {
          Text("NOW PLAYING").font(.system(size: 11, weight: .semibold)).opacity(0.8)
        }
        Spacer()
        Image(systemName: "music.note").font(.system(size: 21, weight: .bold))
      }
      Spacer()
      HStack(alignment: .bottom, spacing: 8) {
        VStack(alignment: .leading, spacing: 3) {
          Text(entry.snapshot.current?.title ?? "Amperfy")
            .font(.system(size: family == .systemLarge ? 22 : 14, weight: .semibold))
            .lineLimit(family == .systemLarge ? 2 : 1)
          Text(entry.snapshot.current?.artist ?? "")
            .font(.system(size: family == .systemLarge ? 17 : 12))
            .opacity(0.85).lineLimit(1)
        }
        Spacer(minLength: 0)
        if family == .systemSmall {
          PlaybackButton(action: .toggle, symbol: entry.snapshot.isPlaying ? "pause.fill" : "play.fill",
                         label: entry.snapshot.isPlaying ? "Pause" : "Play", circular: true)
        }
      }
      if family == .systemLarge {
        PlaybackControls(snapshot: entry.snapshot)
          .frame(maxWidth: .infinity).padding(.top, 8)
      }
    }
    .padding(16)
  }
}

struct RecentlyPlayedView: View {
  let entry: MusicEntry
  @Environment(\.widgetFamily) private var family

  private var items: [WidgetTrack] { entry.snapshot.recent }

  var body: some View {
    content
      .foregroundStyle(.white)
      .containerBackground(for: .widget) { musicGradient }
      .widgetURL(URL(string: "amperfy-widgets://"))
  }

  var content: some View {
    Group {
      if items.isEmpty {
        MusicEmptyView(title: "Recently Played")
      } else {
        GeometryReader { geometry in
          if family == .systemSmall {
            small(size: geometry.size)
          } else {
            collection(size: geometry.size)
          }
        }
      }
    }
  }

  var backdrop: some View { musicGradient }

  private func play(_ item: WidgetTrack) -> WidgetPlaybackIntent {
    WidgetPlaybackIntent(action: .playItem, itemID: item.id)
  }

  private func small(size: CGSize) -> some View {
    let item = items[0]
    let coverSize = max(48, min(size.width - 64, size.height - 76))
    return VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top) {
        Button(intent: play(item)) {
          CoverArtwork(track: item).frame(width: coverSize, height: coverSize)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .buttonStyle(.plain).accessibilityLabel("Play \(item.title)")
        Spacer(minLength: 0)
        Image(systemName: "music.note").font(.system(size: 21, weight: .bold))
      }
      Spacer(minLength: 0)
      HStack(alignment: .bottom, spacing: 4) {
        VStack(alignment: .leading, spacing: 2) {
          Text(item.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
          Text(item.artist).font(.system(size: 12)).opacity(0.8).lineLimit(1)
        }
        Spacer(minLength: 0)
        PlaybackButton(action: .playItem, symbol: "play.fill", label: "Play \(item.title)",
                       size: 13, circular: true, itemID: item.id)
      }
    }
    .padding(16)
  }

  private func collection(size: CGSize) -> some View {
    let large = family == .systemLarge
    let headerHeight: CGFloat = large ? min(108, size.height * 0.33) : 32
    let rows: CGFloat = large ? 2 : 1
    let coverSize = max(24, min((size.width - 32 - 30) / 4,
                              (size.height - 32 - headerHeight - 14 - (rows - 1) * 10) / rows))
    let coverCount = large ? 8 : 4
    let featured = items[0]
    return VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 12) {
        Button(intent: play(featured)) {
          CoverArtwork(track: featured)
            .frame(width: headerHeight, height: headerHeight)
            .shadow(color: .black.opacity(0.14), radius: 4, y: 2)
        }
        .buttonStyle(.plain).accessibilityLabel("Play \(featured.title)")
        VStack(alignment: .leading, spacing: 3) {
          if large {
            Spacer(minLength: 0)
            Text("RECENTLY PLAYED").font(.system(size: 9, weight: .semibold)).opacity(0.7)
          }
          Text(featured.title).font(.system(size: large ? 18 : 13, weight: .semibold))
            .lineLimit(large ? 2 : 1)
          Text(featured.artist).font(.system(size: large ? 15 : 12)).opacity(0.8).lineLimit(1)
          if large { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Image(systemName: "music.note").font(.system(size: large ? 22 : 19, weight: .bold))
      }
      .frame(height: headerHeight)
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
        ForEach(Array(items.dropFirst().prefix(coverCount))) { item in
          Button(intent: play(item)) {
            CoverArtwork(track: item, cornerRadius: 6)
              .frame(height: coverSize)
              .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
          }
          .buttonStyle(.plain).accessibilityLabel("Play \(item.title), \(item.artist)")
        }
      }
      Spacer(minLength: 0)
    }
    .padding(16)
  }
}

struct MusicEmptyView: View {
  let title: String
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(title).font(.system(size: 15, weight: .semibold))
        Spacer(minLength: 0)
        Image(systemName: "music.note").font(.system(size: 21, weight: .bold))
      }
      Spacer()
      Text("Your music, right here.").font(.system(size: 17, weight: .semibold))
      Text("Open Amperfy and play something.").font(.system(size: 13)).opacity(0.8)
    }
    .padding(16)
  }
}

struct AmperfyNowPlaying: Widget {
  let kind = "AmperfyNowPlaying"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MusicProvider()) { NowPlayingView(entry: $0) }
      .configurationDisplayName("Now Playing")
      .description("Control your music without opening Amperfy.")
      .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
      .contentMarginsDisabled()
  }
}

struct AmperfyRecentlyPlayed: Widget {
  let kind = "AmperfyRecentlyPlayed"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MusicProvider()) { RecentlyPlayedView(entry: $0) }
      .configurationDisplayName("Recently Played")
      .description("Quickly play your recently listened to albums and tracks.")
      .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
      .contentMarginsDisabled()
  }
}

#if !WIDGET_GALLERY
@main
struct AmperfyWidgets: WidgetBundle {
  var body: some Widget {
    AmperfyNowPlaying()
    AmperfyRecentlyPlayed()
  }
}
#endif

enum MusicPreview {
  static let snapshot = WidgetSnapshot(
    accountID: "preview",
    current: WidgetTrack(id: "preview-current", serverID: "1", accountID: "preview", kind: "song",
                         title: "Dreams", artist: "Fleetwood Mac", artwork: nil),
    recent: (0 ..< 9).map {
      WidgetTrack(id: "preview-\($0)", serverID: "\($0)", accountID: "preview", kind: "album",
                  title: ["Rumours", "Discovery", "Kind of Blue"][$0 % 3],
                  artist: ["Fleetwood Mac", "Daft Punk", "Miles Davis"][$0 % 3], artwork: nil)
    }, isPlaying: true, canSkip: true
  )
}
