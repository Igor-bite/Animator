// Created by Igor Klyuzhev in 2024

import UIKit

protocol ApplicationCoordinating {
  func start()
}

final class ApplicationCoordinator: ApplicationCoordinating {
  private lazy var window = UIWindow(frame: UIScreen.main.bounds)
  private lazy var navigationController = UINavigationController()
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
