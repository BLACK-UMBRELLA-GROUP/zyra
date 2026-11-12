import Flutter
import UIKit

enum ProfileVideoChannel {
  static func register(messenger: FlutterBinaryMessenger) -> FlutterMethodChannel {
    let channel = FlutterMethodChannel(name: "zyra/profile_video", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "lowPowerMode":
        result(ProcessInfo.processInfo.isLowPowerModeEnabled)
      case "inspect", "thumbnails", "still", "export":
        handleMediaCall(call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    return channel
  }

  private static func handleMediaCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let path = arguments["path"] as? String, path.hasPrefix("/") else {
      result(mediaError)
      return
    }
    let method = call.method
    var time: Int64 = 0
    if method == "export" || method == "still" {
      let timeKey = method == "export" ? "startMs" : "timeMs"
      guard let requestedTime = arguments[timeKey] as? Int64, requestedTime >= 0 else {
        result(mediaError)
        return
      }
      time = requestedTime
    }

    let url = URL(fileURLWithPath: path)
    Task {
      do {
        let media = try await ProfileVideoMedia(url: url)
        let value: Any
        switch method {
        case "inspect":
          value = ["durationMs": media.durationMilliseconds, "videoStartMs": media.startMilliseconds]
        case "thumbnails":
          value = try await media.thumbnails().map(jpeg)
        case "still":
          value = try await jpeg(media.still(timeMilliseconds: time))
        case "export":
          let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("zyra-profile-video-\(UUID().uuidString.lowercased()).mp4")
          try await media.export(startMilliseconds: time, to: output)
          value = output.path
        default:
          await MainActor.run { result(FlutterMethodNotImplemented) }
          return
        }
        await MainActor.run { result(value) }
      } catch {
        await MainActor.run { result(mediaError) }
      }
    }
  }

  private static func jpeg(_ image: CGImage) throws -> FlutterStandardTypedData {
    guard let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.8) else {
      throw ProfileVideoMedia.MediaError.unreadable
    }
    return FlutterStandardTypedData(bytes: data)
  }

  private static var mediaError: FlutterError {
    FlutterError(code: "profile_video_media_error", message: nil, details: nil)
  }
}
