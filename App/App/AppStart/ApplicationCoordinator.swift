// Created by Igor Klyuzhev in 2024

import UIKit

protocol ApplicationCoordinating {
  func start()
}

final class ApplicationCoordinator: ApplicationCoordinating {
  private let window = UIWindow(frame: UIScreen.main.bounds)
  private let navigationController = {
    let navigationController = UINavigationController()
    navigationController.isNavigationBarHidden = true
    return navigationController
  }()
  private let serviceLocator = ServiceLocator()

  func start() {
    showProjectEditorScreen()
    window.rootViewController = navigationController
    window.makeKeyAndVisible()
  }

  private func showProjectEditorScreen() {
    ProjectEditorCoordinator(
      navigationController: navigationController
    ).start()
  }
}
