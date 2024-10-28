// Created by Igor Klyuzhev in 2024

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  private lazy var appCoordinator: ApplicationCoordinating = ApplicationCoordinator()

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    appCoordinator.start()
    return true
  }
}
