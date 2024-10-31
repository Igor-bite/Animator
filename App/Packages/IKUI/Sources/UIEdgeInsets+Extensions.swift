// Created by Igor Klyuzhev in 2024

import UIKit

extension UIEdgeInsets {
  public var inverted: UIEdgeInsets {
    UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
  }

  public var horizontal: CGFloat {
    left + right
  }

  public var vertical: CGFloat {
    top + bottom
  }
  
  public init(top: CGFloat) {
    self.init(top: top, left: .zero, bottom: .zero, right: .zero)
  }

  public init(bottom: CGFloat) {
    self.init(top: .zero, left: .zero, bottom: bottom, right: .zero)
  }

  public init(allSidesEqualTo value: CGFloat) {
    self.init(top: value, left: value, bottom: value, right: value)
  }

  public init(horizontalValue: CGFloat, verticalValue: CGFloat) {
    self.init(
      top: verticalValue,
      left: horizontalValue,
      bottom: verticalValue,
      right: horizontalValue
    )
  }
}
