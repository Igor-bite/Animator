// Created by Igor Klyuzhev in 2024

import SwiftUI
import UIKit

extension UIViewController {
  public func addSwiftUiView(
    view: any View,
    layout: (_ view: UIView) -> Void,
    shouldAddAsSubviewToRootView: Bool = true
  ) -> UIView {
    let viewController = view.wrappedInHostingController
    guard let swiftuiView = viewController.view else {
      assertionFailure()
      return UIView()
    }
    swiftuiView.backgroundColor = .clear
    addChild(viewController)
    if shouldAddAsSubviewToRootView {
      self.view.addSubview(swiftuiView)
    }
    layout(swiftuiView)
    viewController.didMove(toParent: self)
    return swiftuiView
  }
}
