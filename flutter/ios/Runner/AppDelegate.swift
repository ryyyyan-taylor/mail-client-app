import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // TODO(ios): Register BGTaskScheduler tasks here when iOS background sync is implemented.
    // Example:
    //   BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.mail.client.sync", using: nil) { task in
    //     self.handleAppRefresh(task: task as! BGAppRefreshTask)
    //   }
    // Also add "com.mail.client.sync" to BGTaskSchedulerPermittedIdentifiers in Info.plist.

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
