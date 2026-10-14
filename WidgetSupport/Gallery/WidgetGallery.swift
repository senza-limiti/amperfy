// SPDX-License-Identifier: GPL-3.0-or-later
// Simulator-only visual verification app. Not included in the sideload IPA.
import SwiftUI
import UIKit
import WidgetKit

@main
struct WidgetGallery: App {
  private let variant = ProcessInfo.processInfo.arguments.dropFirst().first ?? "recent-large"
  private var family: WidgetFamily {
    if variant.hasSuffix("small") { return .systemSmall }
    if variant.hasSuffix("medium") { return .systemMedium }
    return .systemLarge
  }

  var body: some Scene {
    WindowGroup {
      let entry = MusicEntry(date: .now, snapshot: GalleryArtwork.snapshot)
      ZStack {
        LinearGradient(colors: [Color(red: 0.23, green: 0.13, blue: 0.26),
                                Color(red: 0.07, green: 0.08, blue: 0.18)],
                       startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
        VStack(spacing: 24) {
          Text(variant.hasPrefix("recent") ? "Recently Played" : "Now Playing")
            .font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
          Group {
            if variant.hasPrefix("recent") {
              let view = RecentlyPlayedView(entry: entry, familyOverride: family)
              view.content.background(view.backdrop)
            } else {
              let view = NowPlayingView(entry: entry, familyOverride: family)
              view.content.background(view.backdrop)
            }
          }
          .foregroundStyle(.white)
          .frame(width: family == .systemSmall ? 170 : 364,
                 height: family == .systemLarge ? 382 : 170)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
          .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
          Text("Amperfy").font(.system(size: 15)).foregroundStyle(.white.opacity(0.7))
        }
      }
    }
  }
}

@MainActor
enum GalleryArtwork {
  static let titles = ["Night Drive", "Blue Hours", "Soft Signal", "Afterglow",
                       "Still Life", "Slow Motion", "Daybreak", "In Bloom", "Orbit"]
  static let artists = ["The Midnight", "Nils Frahm", "Tycho", "Bonobo",
                        "Khruangbin", "Slowdive", "Ólafur Arnalds", "Men I Trust", "Four Tet"]
  static let hues: [CGFloat] = [0.83, 0.57, 0.12, 0.03, 0.45, 0.66, 0.08, 0.35, 0.72]

  static func cover(_ index: Int) -> Data? {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
    let image = renderer.image { context in
      let canvas = context.cgContext
      let base = UIColor(hue: hues[index], saturation: 0.64, brightness: 0.8, alpha: 1)
      let dark = UIColor(hue: hues[index], saturation: 0.84, brightness: 0.25, alpha: 1)
      if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [base.cgColor, dark.cgColor] as CFArray,
                                  locations: [0, 1]) {
        canvas.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 400, y: 400), options: [])
      }
      for ring in (0 ..< 5).reversed() {
        canvas.setFillColor(UIColor(hue: (hues[index] + 0.18).truncatingRemainder(dividingBy: 1),
                                   saturation: 0.34, brightness: 1, alpha: CGFloat(5 - ring) * 0.1).cgColor)
        let inset = CGFloat(ring) * 26
        canvas.fillEllipse(in: CGRect(x: 80 + inset, y: 80 + inset,
                                      width: 300 - inset * 2, height: 300 - inset * 2))
      }
      let text = titles[index].uppercased() as NSString
      text.draw(in: CGRect(x: 24, y: 25, width: 352, height: 90), withAttributes: [
        .font: UIFont.systemFont(ofSize: 34, weight: .black), .foregroundColor: UIColor.white,
        .kern: 2,
      ])
      ("AMPERFY • VISUAL TEST" as NSString).draw(at: CGPoint(x: 24, y: 366), withAttributes: [
        .font: UIFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: UIColor.white,
        .kern: 2,
      ])
    }
    return image.jpegData(compressionQuality: 0.9)
  }

  static let snapshot: WidgetSnapshot = {
    let tracks = (0 ..< 9).map {
      WidgetTrack(id: "gallery-\($0)", serverID: "\($0)", accountID: "gallery", kind: "album",
                  title: titles[$0], artist: artists[$0], artwork: cover($0))
    }
    return WidgetSnapshot(accountID: "gallery", current: tracks[0], recent: tracks,
                          isPlaying: true, canSkip: true)
  }()
}
