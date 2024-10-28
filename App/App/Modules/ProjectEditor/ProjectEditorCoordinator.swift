// Created by Igor Klyuzhev in 2024

import UIKit

protocol ProjectEditorCoordinating {}

final class ProjectEditorCoordinator: ProjectEditorCoordinating {
  private let navigationController: UINavigationController

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }

  func start() {
    let viewModel = ProjectEditorViewModel(coordinator: self)
    let view = ProjectEditorViewController(viewModel: viewModel)
    viewModel.view = view
    navigationController.viewControllers = [view]
  }
}
