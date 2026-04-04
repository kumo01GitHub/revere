import Cocoa
import FlutterMacOS
import Logging
import XCTest

@testable import swift_log_transport

// MARK: - Test log handler

private struct RecordingLogHandler: LogHandler {
  final class Storage {
    var entries: [(level: Logger.Level, message: String, metadata: Logger.Metadata)] = []
  }
  let storage: Storage
  var logLevel: Logger.Level = .trace
  var metadata: Logger.Metadata = [:]

  subscript(metadataKey key: String) -> Logger.Metadata.Value? {
    get { metadata[key] }
    set { metadata[key] = newValue }
  }

  func log(level: Logger.Level, message: Logger.Message,
           metadata: Logger.Metadata?, source: String, file: String,
           function: String, line: UInt) {
    var merged = self.metadata
    metadata?.forEach { merged[$0] = $1 }
    storage.entries.append((level: level, message: message.description, metadata: merged))
  }
}

// MARK: - Tests

class RunnerTests: XCTestCase {

  private var storage: RecordingLogHandler.Storage!

  override func setUp() {
    super.setUp()
    storage = RecordingLogHandler.Storage()
    let s = storage!
    LoggingSystem.bootstrapInternal { _ in RecordingLogHandler(storage: s) }
    SwiftLogTransportPlugin.loggerCache.removeAll()
  }

  // --- handle(_:result:) ---

  func testHandleLogReturnsNil() {
    let plugin = SwiftLogTransportPlugin()
    let args: [String: Any] = ["level": "info", "message": "hello",
                                "context": "", "label": "Test", "metadata": [String: String]()]
    let call = FlutterMethodCall(methodName: "log", arguments: args)
    let exp = expectation(description: "result called")
    plugin.handle(call) { result in
      XCTAssertNil(result)
      exp.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testHandleUnknownMethodReturnsNotImplemented() {
    let plugin = SwiftLogTransportPlugin()
    let call = FlutterMethodCall(methodName: "unknown", arguments: nil)
    let exp = expectation(description: "result called")
    plugin.handle(call) { result in
      XCTAssertTrue(result is FlutterMethodNotImplemented.Type ||
                    (result as? NSObject) == FlutterMethodNotImplemented)
      exp.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  // --- logEvent(args:) ---

  func testLogEventWritesMessage() {
    SwiftLogTransportPlugin.logEvent(args: [
      "level": "info", "message": "test message", "context": "ctx", "label": "App",
    ])
    XCTAssertEqual(storage.entries.count, 1)
    XCTAssertEqual(storage.entries[0].message, "test message")
  }

  func testLogEventLevelMapping() {
    let cases: [(String, Logger.Level)] = [
      ("trace", .trace), ("debug", .debug), ("info", .info),
      ("warn", .warning), ("error", .error), ("fatal", .critical),
    ]
    for (levelStr, expected) in cases {
      storage.entries.removeAll()
      SwiftLogTransportPlugin.logEvent(args: [
        "level": levelStr, "message": "msg", "context": "", "label": levelStr,
      ])
      XCTAssertEqual(storage.entries.first?.level, expected, "level=\(levelStr)")
    }
  }

  func testLogEventUnknownLevelDefaultsToInfo() {
    SwiftLogTransportPlugin.logEvent(args: [
      "level": "verbose", "message": "msg", "context": "", "label": "App",
    ])
    XCTAssertEqual(storage.entries.first?.level, .info)
  }

  func testLogEventSetsMetadata() {
    SwiftLogTransportPlugin.logEvent(args: [
      "level": "info", "message": "msg", "context": "svc",
      "label": "App", "metadata": ["env": "prod"],
    ])
    XCTAssertEqual(storage.entries.first?.metadata["env"], "prod")
  }

  func testLogEventCachesLoggerByLabelAndContext() {
    SwiftLogTransportPlugin.logEvent(args: [
      "level": "info", "message": "first", "context": "svc", "label": "App",
    ])
    SwiftLogTransportPlugin.logEvent(args: [
      "level": "info", "message": "second", "context": "svc", "label": "App",
    ])
    XCTAssertEqual(SwiftLogTransportPlugin.loggerCache.count, 1)
  }

}
