// Created by Igor Klyuzhev in 2024

import UIKit
import SwiftUI

extension UIViewController {
  public func addSwiftUiView(
    view: any View,
    layout: (_ view: UIView) -> Void,
    shouldAddAsSubviewToRootView: Bool = true
  ) {
    let viewController = view.wrappedInHostingController
    guard let swiftuiView = viewController.view else { return }
    swiftuiView.backgroundColor = .clear
    addChild(viewController)
    if shouldAddAsSubviewToRootView {
      self.view.addSubview(swiftuiView)
    }
    layout(swiftuiView)
    viewController.didMove(toParent: self)
  }
}
