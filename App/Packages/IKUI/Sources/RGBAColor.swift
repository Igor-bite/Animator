// Created by Igor Klyuzhev in 2024

import IKUtils
import UIKit

public struct RGBAColor {
  public var red: CGFloat
  public var green: CGFloat
  public var blue: CGFloat
  public var alpha: CGFloat

  public init(
    red: CGFloat,
    green: CGFloat,
    blue: CGFloat,
    alpha: CGFloat
  ) {
    self.red = clamp(red, min: 0, max: 1)
    self.green = clamp(green, min: 0, max: 1)
    self.blue = clamp(blue, min: 0, max: 1)
    self.alpha = clamp(alpha, min: 0, max: 1)
  }

  public var uiColor: UIColor {
    UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }
}

extension UIColor {
  public var rgba: RGBAColor {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    guard getRed(
      &red,
      green: &green,
      blue: &blue,
      alpha: &alpha
    ) else {
      assertionFailure()
      return RGBAColor(red: 1, green: 1, blue: 1, alpha: 1)
    }

    return RGBAColor(red: red, green: green, blue: blue, alpha: alpha)
  }
}
