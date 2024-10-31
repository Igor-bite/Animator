// Created by Igor Klyuzhev in 2024

import UIKit

extension UIControl {
  public func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping () -> Void) {
    addAction(UIAction { (_: UIAction) in closure() }, for: controlEvents)
  }
}
