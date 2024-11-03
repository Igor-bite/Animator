// Created by Igor Klyuzhev in 2024

import UIKit

extension UIView {
  public func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
    layer.cornerRadius = radius
    layer.cornerCurve = .continuous
    layer.maskedCorners = CACornerMask(corners: corners)
    layer.masksToBounds = true
  }
}

extension CACornerMask {
  public init(corners: UIRectCorner) {
    self.init()
    if corners.contains(.topLeft) {
      insert(.layerMinXMinYCorner)
    }
    if corners.contains(.topRight) {
      insert(.layerMaxXMinYCorner)
    }
    if corners.contains(.bottomLeft) {
      insert(.layerMinXMaxYCorner)
    }
    if corners.contains(.bottomRight) {
      insert(.layerMaxXMaxYCorner)
    }
  }
}
