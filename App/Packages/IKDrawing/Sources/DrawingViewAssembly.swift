// Created by Igor Klyuzhev in 2024

import UIKit

public enum DrawingViewAssembly {
  public static func make(
    config: DrawingViewConfiguration
  ) -> (view: UIView, interactor: DrawingViewInteractor) {
    let controller = DrawingViewController(config: config)
    let view = DrawingView(controller: controller)
    controller.view = view

    return (view, controller)
  }
}
