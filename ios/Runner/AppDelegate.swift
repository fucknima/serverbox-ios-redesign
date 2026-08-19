import UIKit
import WidgetKit
import Flutter
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        #if DEBUG
        // Crash diagnosis only: writes the NSException reason + stack to the
        // temp dir so an SDK/engine abort can be traced on a test build.
        // Compile-dropped from release, where it would only hide system logs.
        NSSetUncaughtExceptionHandler { exception in
            let reason = exception.reason ?? "nil"
            let stack = exception.callStackSymbols.joined(separator: "\n")
            let payload = "REASON:\n\(reason)\n\nSTACK:\n\(stack)\n"
            let path = NSTemporaryDirectory() + "uncaught_exception.txt"
            try? payload.write(toFile: path, atomically: true, encoding: .utf8)
            NSLog("UNCAUGHT EXCEPTION: %@", payload)
        }
        #endif
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        setupMethodChannels(binaryMessenger: engineBridge.applicationRegistrar.messenger())
    }

    private func setupMethodChannels(binaryMessenger: FlutterBinaryMessenger) {
        let homeWidgetChannel = FlutterMethodChannel(name: "tech.lolli.toolbox/home_widget", binaryMessenger: binaryMessenger)
        homeWidgetChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "update":
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadTimelines(ofKind: "StatusWidget")
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        })

        let mainChannel = FlutterMethodChannel(name: "tech.lolli.toolbox/main_chan", binaryMessenger: binaryMessenger)
        mainChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "updateHomeWidget":
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadTimelines(ofKind: "StatusWidget")
                }
                result(nil)
            case "startLiveActivity":
                if #available(iOS 16.2, *) {
                    if let payload = call.arguments as? String {
                        LiveActivityManager.start(json: payload)
                    }
                }
                result(nil)
            case "updateLiveActivity":
                if #available(iOS 16.2, *) {
                    if let payload = call.arguments as? String {
                        LiveActivityManager.update(json: payload)
                    }
                }
                result(nil)
            case "stopLiveActivity":
                if #available(iOS 16.2, *) {
                    Task {
                        await LiveActivityManager.stop()
                        result(nil)
                    }
                } else {
                    result(nil)
                }
            case "setAccessoryWidgetUrl":
                // The accessory families can't carry the intent configuration
                // the home-screen ones use, so they read this key instead —
                // see StatusWidget.getTimeline.
                let defaults = UserDefaults(suiteName: appGroupId)
                if let url = call.arguments as? String, !url.isEmpty {
                    defaults?.set(url, forKey: accessoryKey)
                } else {
                    defaults?.removeObject(forKey: accessoryKey)
                }
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadTimelines(ofKind: "StatusWidget")
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "https" || url.scheme == "http" {
            UIApplication.shared.open(url)
        } else {
            // Pass
        }
        return true
    }

    override func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // UIScene apps use this callback when the user closes the app from the
        // app switcher. applicationWillTerminate is not reliable for that path.
        if #available(iOS 16.2, *) {
            Task { await LiveActivityManager.stop() }
        }
        // The system calls this at the *next* launch when scene sessions were
        // discarded while the app was not running. FlutterAppDelegate does not
        // implement this optional UIApplicationDelegate method, so an
        // unconditional `super` forward throws "unrecognized selector" and the
        // app aborts right at launch — the "crash on second open after being
        // killed from the app switcher" report. Forward only when the
        // superclass actually has something to run.
        if FlutterAppDelegate.instancesRespond(to: #selector(UIApplicationDelegate.application(_:didDiscardSceneSessions:))) {
            super.application(application, didDiscardSceneSessions: sceneSessions)
        }
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        // Stop Live Activity when app is about to terminate
        if #available(iOS 16.2, *) {
            Task { await LiveActivityManager.stop() }
        }
    }
}
