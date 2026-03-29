import Foundation
#if canImport(FlutterMacOS)
import FlutterMacOS
#endif
#if canImport(Flutter)
import Flutter
#endif
#if canImport(Logging)
import Logging
#endif

@objc public class SwiftLogTransportPlugin: NSObject {
  static var loggerCache: [String: Logger] = [:]

  // For Flutter iOS
  @objc public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "swift_log_transport", binaryMessenger: registrar.messenger())
    let instance = SwiftLogTransportPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // For Flutter macOS
  @objc public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "swift_log_transport", binaryMessenger: registrar.messenger)
    let instance = SwiftLogTransportPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
}

extension SwiftLogTransportPlugin: FlutterPlugin {
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "log", let args = call.arguments as? [String: Any] {
      Self.logEvent(args: args)
      result(nil)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  static func logEvent(args: [String: Any]) {
#if canImport(Logging)
    let level = (args["level"] as? String)?.lowercased() ?? "info"
    let message = args["message"] as? String ?? ""
    let timestamp = args["timestamp"] as? String ?? ""
    let error = args["error"] as? String
    let stackTrace = args["stackTrace"] as? String
    let context = args["context"] as? String ?? ""
    let label = args["label"] as? String ?? "Revere"
    let metadataMap = args["metadata"] as? [String: String]

    let logger: Logger
    let loggerKey = "\(label):\(context)"
    if let cached = loggerCache[loggerKey] {
      logger = cached
    } else {
      var newLogger = Logger(label: label, factory: StreamLogHandler.standardOutput)
      newLogger[metadataKey: "category"] = .string(context)
      if let metadataMap = metadataMap {
        for (k, v) in metadataMap { newLogger[metadataKey: k] = .string(v) }
      }
      loggerCache[loggerKey] = newLogger
      logger = newLogger
    }
    if let metadataMap = metadataMap {
      for (k, v) in metadataMap { logger[metadataKey: k] = .string(v) }
    }

    switch level {
    case "trace": logger.trace("\(logMsg)")
    case "debug": logger.debug("\(logMsg)")
    case "info": logger.info("\(logMsg)")
    case "warn": logger.warning("\(logMsg)")
    case "error": logger.error("\(logMsg)")
    case "fatal": logger.critical("\(logMsg)")
    default: logger.info("\(logMsg)")
    }
#else
    // Fallback: print if Logging is not available
    print("[SwiftLog] \(args)")
#endif
  }
}
