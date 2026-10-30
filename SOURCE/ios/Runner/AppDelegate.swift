import Flutter
import UIKit
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var appIconChannel: FlutterMethodChannel?
  private var profilePhotoChannel: FlutterMethodChannel?
  private var roughLocation: ZyraRoughLocation?

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
    roughLocation = ZyraRoughLocation(messenger: engineBridge.applicationRegistrar.messenger())

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


// One foreground fix, rounded BEFORE Flutter. No exact coordinate, raw error,
// altitude, speed, preference, server write or log crosses this boundary.
private final class ZyraRoughLocation: NSObject, CLLocationManagerDelegate {
  private let channel: FlutterMethodChannel
  private var watcher: CLLocationManager?
  private var active: CLLocationManager?
  private var completion: FlutterResult?
  private var deadline: DispatchWorkItem?
  private var started = false
  private var backgroundObserver: NSObjectProtocol?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "app.zyraconnect.zyra/rough_location",
                                   binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(["status": "unavailable"]); return }
      switch call.method {
      case "status": result(self.status())
      case "request": self.request(result)
      case "cancel": self.finish(["status": "cancelled"]); result(nil)
      case "openSettings":
        self.finish(["status": "cancelled"])
        guard UIApplication.shared.applicationState == .active,
              let url = URL(string: UIApplication.openSettingsURLString) else {
          result(false); return
        }
        UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
      default: result(FlutterMethodNotImplemented)
      }
    }
    backgroundObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
    ) { [weak self] _ in self?.finish(["status": "cancelled"]) }
  }

  // Lazy: opening the app/Filters/Home town does not even create a manager.
  private func observePermission() -> CLLocationManager {
    if let watcher { return watcher }
    let manager = CLLocationManager()
    manager.desiredAccuracy = kCLLocationAccuracyReduced
    watcher = manager
    manager.delegate = self
    return manager
  }

  private func status() -> String {
    let permission = observePermission().authorizationStatus
    switch permission {
    case .authorizedWhenInUse, .authorizedAlways: return "allowed"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "unavailable"
    }
  }

  private func request(_ result: @escaping FlutterResult) {
    finish(["status": "cancelled"])
    guard UIApplication.shared.applicationState == .active else {
      result(["status": "unavailable"]); return
    }
    let permission = status()
    guard permission == "allowed" || permission == "notDetermined" else {
      result(["status": permission]); return
    }
    let manager = CLLocationManager()
    manager.desiredAccuracy = kCLLocationAccuracyReduced
    manager.distanceFilter = kCLDistanceFilterNone
    completion = result
    active = manager
    started = false
    manager.delegate = self
    let timeout = DispatchWorkItem { [weak self] in
      self?.finish(["status": "unavailable"])
    }
    deadline = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timeout)
    if permission == "notDetermined" { manager.requestWhenInUseAuthorization() }
    else { start(manager) }
  }

  private func start(_ manager: CLLocationManager) {
    guard manager === active, !started,
          UIApplication.shared.applicationState != .background else { return }
    started = true
    manager.requestLocation()
  }

  private func finish(_ value: [String: Any]) {
    deadline?.cancel()
    deadline = nil
    active?.stopUpdatingLocation()
    active?.delegate = nil
    active = nil
    started = false
    let reply = completion
    completion = nil
    reply?(value)
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard manager === active || manager === watcher else { return }
    let permission = status()
    channel.invokeMethod("permissionChanged", arguments: permission)
    if permission == "denied" || permission == "restricted" {
      finish(["status": permission])
    } else if permission == "allowed", let active { start(active) }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard manager === active else { return }
    guard UIApplication.shared.applicationState != .background,
          status() == "allowed", let fix = locations.last,
          fix.horizontalAccuracy >= 0,
          abs(fix.timestamp.timeIntervalSinceNow) <= 60,
          CLLocationCoordinate2DIsValid(fix.coordinate) else {
      finish(["status": "unavailable"]); return
    }
    // About 11 km in latitude; even full accuracy granted in Settings never
    // escapes. Dart independently refuses anything off this coarse grid.
    let latitude = (fix.coordinate.latitude * 10).rounded() / 10
    let longitude = (fix.coordinate.longitude * 10).rounded() / 10
    finish(["status": "allowed", "latitude": latitude, "longitude": longitude])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    guard manager === active else { return }
    finish(["status": status() == "denied" ? "denied" : "unavailable"])
  }

  deinit {
    if let backgroundObserver { NotificationCenter.default.removeObserver(backgroundObserver) }
    deadline?.cancel()
    active?.stopUpdatingLocation()
    active?.delegate = nil
    watcher?.delegate = nil
  }
}
