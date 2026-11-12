import AVFoundation
import Foundation

struct ProfileVideoMedia {
  enum MediaError: Error {
    case unreadable
    case exportFailed
  }

  private static let maximumDuration = CMTime(value: 10, timescale: 1)
  private let asset: AVURLAsset
  private let video: AVAssetTrack
  private let videoRange: CMTimeRange

  var durationMilliseconds: Int64 {
    CMTimeConvertScale(videoRange.duration, timescale: 1_000, method: .roundTowardPositiveInfinity).value
  }

  var startMilliseconds: Int64 {
    CMTimeConvertScale(videoRange.start, timescale: 1_000, method: .roundTowardPositiveInfinity).value
  }

  init(url: URL) async throws {
    let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    guard let video = try await asset.loadTracks(withMediaType: .video).first else {
      throw MediaError.unreadable
    }
    let videoRange = try await video.load(.timeRange)
    guard videoRange.start.isNumeric, videoRange.duration.isNumeric,
          videoRange.duration > .zero else {
      throw MediaError.unreadable
    }
    self.asset = asset
    self.video = video
    self.videoRange = videoRange
  }

  func thumbnails() async throws -> [CGImage] {
    let generator = makeImageGenerator(maximumSize: CGSize(width: 160, height: 160))
    let count: Int32 = 10
    var images: [CGImage] = []
    for index in 0..<count {
      // Sample the middle of each tenth so the last request stays inside the clip.
      let offset = CMTimeMultiplyByRatio(videoRange.duration, multiplier: 2 * index + 1, divisor: 2 * count)
      images.append(try await image(at: videoRange.start + offset, using: generator))
    }
    return images
  }

  func still(timeMilliseconds: Int64) async throws -> CGImage {
    let generator = makeImageGenerator(maximumSize: CGSize(width: 960, height: 960))
    let requestedOffset = CMTime(value: timeMilliseconds, timescale: 1_000)
    let lastOffset = max(.zero, videoRange.duration - CMTime(value: 1, timescale: 1_000))
    return try await image(at: videoRange.start + min(requestedOffset, lastOffset), using: generator)
  }

  func export(startMilliseconds: Int64, to output: URL) async throws {
    let duration = min(videoRange.duration, Self.maximumDuration)
    let requestedStart = CMTime(value: startMilliseconds, timescale: 1_000)
    let start = max(.zero, min(requestedStart, videoRange.duration - duration))
    let range = CMTimeRange(start: videoRange.start + start, duration: duration)

    let composition = AVMutableComposition()
    guard let track = composition.addMutableTrack(
      withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid
    ) else {
      throw MediaError.exportFailed
    }
    try track.insertTimeRange(range, of: video, at: .zero)
    track.preferredTransform = try await video.load(.preferredTransform)
    guard let session = AVAssetExportSession(
      asset: composition, presetName: AVAssetExportPresetMediumQuality
    ), session.supportedFileTypes.contains(.mp4) else {
      throw MediaError.exportFailed
    }
    session.timeRange = CMTimeRange(start: .zero, duration: duration)
    session.shouldOptimizeForNetworkUse = true

    do {
      try await write(session, to: output)
      let exported = AVURLAsset(url: output, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
      let exportedDuration = try await exported.load(.duration)
      let videoTracks = try await exported.loadTracks(withMediaType: .video)
      let audioTracks = try await exported.loadTracks(withMediaType: .audio)
      guard exportedDuration.isNumeric, exportedDuration > .zero,
            exportedDuration <= Self.maximumDuration, videoTracks.count == 1, audioTracks.isEmpty else {
        throw MediaError.exportFailed
      }
    } catch {
      try? FileManager.default.removeItem(at: output)
      throw error
    }
  }

  private func makeImageGenerator(maximumSize: CGSize) -> AVAssetImageGenerator {
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = maximumSize
    // Honor the requested position, with room to resolve a nearby decodable frame.
    let tolerance = CMTime(value: 1, timescale: 4)
    generator.requestedTimeToleranceBefore = tolerance
    generator.requestedTimeToleranceAfter = tolerance
    return generator
  }

  private func image(at time: CMTime, using generator: AVAssetImageGenerator) async throws -> CGImage {
    if #available(iOS 16.0, macOS 13.0, *) {
      return try await generator.image(at: time).image
    }
    return try generator.copyCGImage(at: time, actualTime: nil)
  }

  private func write(_ session: AVAssetExportSession, to output: URL) async throws {
    if #available(iOS 18.0, macOS 15.0, *) {
      try await session.export(to: output, as: .mp4)
      return
    }
    session.outputURL = output
    session.outputFileType = .mp4
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      session.exportAsynchronously {
        continuation.resume()
      }
    }
    guard session.status == .completed else {
      throw session.error ?? MediaError.exportFailed
    }
  }
}
