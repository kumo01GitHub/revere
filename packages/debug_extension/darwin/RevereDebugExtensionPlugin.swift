import Foundation
#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
#endif

public class RevereDebugExtensionPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "revere_debug_extension", binaryMessenger: registrar.messenger)
    let instance = RevereDebugExtensionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getMetrics" {
      let cpu = Self.getCPUUsage()
      let memory = Self.getMemoryUsage()
      result(["cpu": cpu, "memory": memory])
    } else {
      result(FlutterMethodNotImplemented)
    }
    // Returns CPU usage as a percentage (process-wide, sum of all threads)
    private static func getCPUUsage() -> Double {
      var threads: thread_act_array_t? = nil
      var threadCount: mach_msg_type_number_t = 0
      var totalUsage: Double = 0.0
      let kr = task_threads(mach_task_self_, &threads, &threadCount)
      if kr == KERN_SUCCESS, let threads = threads {
        for i in 0..<Int(threadCount) {
          var info = thread_basic_info()
          var count = mach_msg_type_number_t(THREAD_INFO_MAX)
          let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
              thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
            }
          }
          if result == KERN_SUCCESS {
            let threadInfo = info as thread_basic_info
            if (threadInfo.flags & TH_FLAGS_IDLE) == 0 {
              totalUsage += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
          }
        }
        // Deallocate the thread list
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.size))
      }
      return totalUsage
    }

    // Returns memory usage in bytes (resident set size)
    private static func getMemoryUsage() -> Int {
      var info = mach_task_basic_info()
      var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
      let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
          task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
      }
      if kerr == KERN_SUCCESS {
        return Int(info.resident_size)
      } else {
        return 0
      }
    }
  }
}
