import Foundation
#if os(macOS)
import FlutterMacOS
#else
import Flutter
#endif
#if canImport(Logging)
import Logging
#endif

@objc public class SwiftLogTransportPlugin: NSObject, FlutterPlugin {
  #if canImport(Logging)
  static var loggerCache: [String: Logger] = [:]
  #endif

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(macOS)
    let channel = FlutterMethodChannel(name: "swift_log_transport", binaryMessenger: registrar.messenger)
    #else
    let channel = FlutterMethodChannel(name: "swift_log_transport", binaryMessenger: registrar.messenger())
    #endif
    let instance = SwiftLogTransportPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "log", let args = call.arguments as? [String: Any] {
      Self.logEvent(args: args)
      result(nil)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  static func logEvent(args: [String: Any]) {
    let level = (args["level"] as? String)?.lowercased() ?? "info"
    let message = args["message"] as? String ?? ""
    let context = args["context"] as? String ?? ""
    let label = args["label"] as? String ?? "Revere"
    let metadataMap = args["metadata"] as? [String: String]

    #if canImport(Logging)
    let loggerKey = "\(label):\(context)"
    var logger: Logger
    if let cached = loggerCache[loggerKey] {
      logger = cached
    } else {
      var newLogger = Logger(label: label, factory: { l in StreamLogHandler.standardOutput(label: l) })
      newLogger[metadataKey: "category"] = Logger.MetadataValue.string(context)
      if let metadataMap = metadataMap {
        for (k, v) in metadataMap { newLogger[metadataKey: k] = Logger.MetadataValue.string(v) }
      }
      loggerCache[loggerKey] = newLogger
      logger = newLogger
    }

    switch level {
    case "trace": logger.trace("\(message)")
    case "debug": logger.debug("\(message)")
    case "info": logger.info("\(message)")
    case "warn": logger.warning("\(message)")
    case "error": logger.error("\(message)")
    case "fatal": logger.critical("\(message)")
    default: logger.info("\(message)")
    }
    #else
    // NSLog fallback for CocoaPods builds (swift-log is unavailable)
    NSLog("[%@][%@][%@] %@", label, context, level.uppercased(), message)
    #endif
  }
}
