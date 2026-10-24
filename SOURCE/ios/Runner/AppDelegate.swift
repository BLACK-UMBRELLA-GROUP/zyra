import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var appIconChannel: FlutterMethodChannel?
  private var profilePhotoChannel: FlutterMethodChannel?

  private func normaliseProfilePhoto(
    arguments: Any?,
    completion: @escaping (FlutterStandardTypedData?, FlutterError?) -> Void
  ) {
    guard
      let arguments = arguments as? [String: Any],
      let maxDimension = arguments["maxDimension"] as? NSNumber,
      let quality = arguments["quality"] as? NSNumber,
      (arguments["data"] is FlutterStandardTypedData || arguments["path"] is String),
      maxDimension.doubleValue > 0,
      quality.doubleValue >= 0,
      quality.doubleValue <= 100
    else {
      completion(
        nil,
        FlutterError(
          code: "photo_bad_arguments",
          message: "The selected photo could not be prepared.",
          details: nil
        )
      )
      return
    }

    let suppliedData = (arguments["data"] as? FlutterStandardTypedData)?.data
    let suppliedPath = arguments["path"] as? String

    DispatchQueue.global(qos: .userInitiated).async {
      autoreleasepool {
        let sourceData = suppliedData ?? suppliedPath.flatMap {
          try? Data(contentsOf: URL(fileURLWithPath: $0))
        }
        guard
          let sourceData,
          let sourceImage = UIImage(data: sourceData),
          sourceImage.size.width > 0,
          sourceImage.size.height > 0
        else {
          DispatchQueue.main.async {
            completion(
              nil,
              FlutterError(
                code: "photo_decode_failed",
                message: "The selected photo format could not be prepared.",
                details: nil
              )
            )
          }
          return
        }

        let longestEdge = max(sourceImage.size.width, sourceImage.size.height)
        let scale = min(1.0, maxDimension.doubleValue / longestEdge)
        let targetSize = CGSize(
          width: max(1, (sourceImage.size.width * scale).rounded()),
          height: max(1, (sourceImage.size.height * scale).rounded())
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let outputData = renderer.jpegData(
          withCompressionQuality: quality.doubleValue / 100.0
        ) { context in
          UIColor.black.setFill()
          context.fill(CGRect(origin: .zero, size: targetSize))
          // UIImage.draw applies the source orientation while rendering. The
          // fresh bitmap and JPEG carry no EXIF, GPS, capture date or device
          // metadata into Flutter or Storage.
          sourceImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard !outputData.isEmpty else {
          DispatchQueue.main.async {
            completion(
              nil,
              FlutterError(
                code: "photo_encode_failed",
                message: "The selected photo could not be encoded safely.",
                details: nil
              )
            )
          }
          return
        }

        DispatchQueue.main.async {
          completion(FlutterStandardTypedData(bytes: outputData), nil)
        }
      }
    }
  }

  private func appIconState(for application: UIApplication) -> [String: Any] {
    var state: [String: Any] = [
      "supported": application.supportsAlternateIcons,
    ]
    if let iconName = application.alternateIconName {
      state["iconName"] = iconName
    } else {
      state["iconName"] = NSNull()
    }
    return state
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let photoChannel = FlutterMethodChannel(
      name: "app.zyraconnect.zyra/profile_photo",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    photoChannel.setMethodCallHandler { call, result in
      guard call.method == "normaliseProfilePhoto" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.normaliseProfilePhoto(arguments: call.arguments) { data, error in
        if let error {
          result(error)
        } else {
          result(data)
        }
      }
    }
    profilePhotoChannel = photoChannel

    let channel = FlutterMethodChannel(
      name: "app.zyraconnect.zyra/app_icon",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      let application = UIApplication.shared
      switch call.method {
      case "getAppIconState":
        result(self.appIconState(for: application))
      case "setAppIcon":
        guard application.supportsAlternateIcons else {
          result(
            FlutterError(
              code: "unsupported",
              message: "This iPhone does not support alternate app icons.",
              details: nil
            )
          )
          return
        }
        guard let arguments = call.arguments as? [String: Any] else {
          result(
            FlutterError(
              code: "bad_arguments",
              message: "The app icon request was invalid.",
              details: nil
            )
          )
          return
        }

        let rawName = arguments["iconName"]
        let iconName: String?
        if rawName == nil || rawName is NSNull {
          iconName = nil
        } else if let requestedName = rawName as? String {
          iconName = requestedName
        } else {
          result(
            FlutterError(
              code: "bad_arguments",
              message: "The app icon name was invalid.",
              details: nil
            )
          )
          return
        }

        let allowedNames: Set<String> = [
          "ZyraGoldHalo",
          "ZyraOrbitLight",
          "ZyraTwinGlow",
          "ZyraOpenFrame",
          "ZyraEditorialGold",
          "ZyraRisingDawn",
          "ZyraQuietMonogram",
          "ZyraSilkRibbon",
          "ZyraConstellation",
          "ZyraRoyalSeal",
        ]
        if let iconName, !allowedNames.contains(iconName) {
          result(
            FlutterError(
              code: "unknown_icon",
              message: "That app icon is not bundled with ZYRA.",
              details: nil
            )
          )
          return
        }

        DispatchQueue.main.async {
          application.setAlternateIconName(iconName) { error in
            DispatchQueue.main.async {
              if let error {
                result(
                  FlutterError(
                    code: "change_failed",
                    message: error.localizedDescription,
                    details: nil
                  )
                )
              } else {
                result(self.appIconState(for: application))
              }
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    appIconChannel = channel
  }
}
