// Created by Igor Klyuzhev in 2024

import UIKit

enum FramesPlayerAssembly {
  static func make(
    with config: FramesPlayerConfig
  ) -> (
    view: UIView,
    interactor: FramesPlayerInteractor
  ) {
    let controller = FramesPlayerController(config: config)
    let view = FramesPlayerView(controller: controller)
    controller.view = view
    return (view, controller)
  }
}
