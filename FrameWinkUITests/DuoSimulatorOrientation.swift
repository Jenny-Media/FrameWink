#if targetEnvironment(simulator)
import Darwin
import Foundation
import ObjectiveC
import UIKit

// UI-test runner only. Xcode 27.1 can update XCUIDevice.orientation without
// rotating the Duo scene. Send the Simulator's own control event, then let the
// caller verify the real app-window geometry. No app layout/state is overridden.
// Protocol investigation: https://github.com/appium/appium-ios/pull/81
// These fixture tests start on the cover panel; native Book/Tabletop acceptance
// is separate. Never compile this Simulator transport into a device build.
enum DuoSimulatorOrientation {
    static let isAvailable: Bool = {
        guard dlopen("/System/Library/Frameworks/CoreMotion.framework/CoreMotion", RTLD_LAZY) != nil,
              let manager = NSClassFromString("CMAngleManager"),
              let method = class_getClassMethod(manager, NSSelectorFromString("isAvailable"))
        else { return false }
        typealias Availability = @convention(c) (AnyClass, Selector) -> Bool
        let available = unsafeBitCast(method_getImplementation(method), to: Availability.self)
        return available(manager, NSSelectorFromString("isAvailable"))
    }()

    static func selectCoverDisplay() -> Bool {
        dispatch(source: "hinge-slider-control", type: "range", value: 0)
    }

    static func rotateCover(to orientation: UIDeviceOrientation) -> Bool {
        let value: String
        switch orientation {
        case .portrait: value = "portrait"
        case .landscapeLeft: value = "landscape-left"
        case .landscapeRight: value = "landscape-right"
        default: return false
        }
        return dispatch(source: "orientation-picker-control", type: "enum", value: value)
    }

    private typealias Serialize = @convention(c) (CFTypeRef, CFOptionFlags) -> Unmanaged<CFData>?
    private typealias CreateEvent = @convention(c) (
        CFAllocator?, UInt64, UInt32, UInt32, UInt32, UnsafePointer<UInt8>?, CFIndex, UInt32
    ) -> Unmanaged<CFTypeRef>?
    private typealias CreateClient = @convention(c) (CFAllocator?) -> Unmanaged<CFTypeRef>?
    private typealias DispatchEvent = @convention(c) (CFTypeRef, CFTypeRef) -> Void

    private struct Transport {
        let serialize: Serialize
        let createEvent: CreateEvent
        let createClient: CreateClient
        let dispatchEvent: DispatchEvent
    }

    private static let transport: Transport? = {
        guard let library = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY),
              let serialize = dlsym(library, "IOCFSerialize"),
              let createEvent = dlsym(library, "IOHIDEventCreateVendorDefinedEvent"),
              let createClient = dlsym(library, "IOHIDEventSystemClientCreate"),
              let dispatchEvent = dlsym(library, "IOHIDEventSystemClientDispatchEvent")
        else { return nil }
        return Transport(
            serialize: unsafeBitCast(serialize, to: Serialize.self),
            createEvent: unsafeBitCast(createEvent, to: CreateEvent.self),
            createClient: unsafeBitCast(createClient, to: CreateClient.self),
            dispatchEvent: unsafeBitCast(dispatchEvent, to: DispatchEvent.self)
        )
    }()

    private static func dispatch(source: String, type: String, value: Any) -> Bool {
        guard isAvailable, let transport else { return false }
        let payload = [
            "provider": "com.apple.Virtualization.VirtualMachines",
            "source": source, "type": type, "value": value
        ] as CFDictionary
        // IOCF's binary format (option 1) is distinct from a binary plist.
        guard let data = transport.serialize(payload, 1)?.takeRetainedValue(),
              let event = transport.createEvent(
                nil, mach_absolute_time(), 0xff61, 0x5b, 0,
                CFDataGetBytePtr(data), CFDataGetLength(data), 0
              )?.takeRetainedValue(),
              let client = transport.createClient(nil)?.takeRetainedValue()
        else { return false }
        transport.dispatchEvent(client, event)
        return true // Submission only; existing window-geometry assertions still gate success.
    }
}
#endif
