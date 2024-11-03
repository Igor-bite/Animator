// Created by Igor Klyuzhev in 2024

import CoreGraphics
import UIKit

extension CGSize {
  public static var infinite: CGSize {
    CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
  }

  public func ceiled(toStep step: CGFloat = 1) -> Self {
    Self(width: width.ceiled(toStep: step), height: height.ceiled(toStep: step))
  }
}

extension CGSize {
  public init(squareDimension: CGFloat) {
    self.init(
      width: squareDimension,
      height: squareDimension
    )
  }

  public func inset(by insets: UIEdgeInsets) -> CGSize {
    CGSize(
      width: width - insets.left - insets.right,
      height: height - insets.top - insets.bottom
    )
  }

  public var maxDimension: CGFloat {
    max(width, height)
  }

  public var minDimension: CGFloat {
    min(width, height)
  }

  public func expanded(by insets: UIEdgeInsets) -> CGSize {
    CGSize(
      width: width + insets.left + insets.right,
      height: height + insets.top + insets.bottom
    )
  }

  public func swapDimensions() -> CGSize {
    CGSize(width: height, height: width)
  }
}

extension CGSize {
  public static var size32: CGSize {
    CGSize(squareDimension: 32)
  }
}
