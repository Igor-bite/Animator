// Created by Igor Klyuzhev in 2024

import UIKit

extension UIColor {
  public convenience init(hex: String) {
    let r, g, b, a: CGFloat

    let start = hex.index(hex.startIndex, offsetBy: 1)
    let hexColor = String(hex[start...])

    let scanner = Scanner(string: hexColor)
    var hexNumber: UInt64 = 0

    if scanner.scanHexInt64(&hexNumber) {
      r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
      g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
      b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
      a = CGFloat(hexNumber & 0x000000ff) / 255

      self.init(red: r, green: g, blue: b, alpha: a)
      return
    } else {
      assertionFailure("Not correct hex string for color initializer - \(hex)")
      self.init(red: .zero, green: .zero, blue: .zero, alpha: .zero)
    }
  }

  public convenience init(
    light lightColor: @escaping @autoclosure () -> UIColor,
    dark darkColor: @escaping @autoclosure () -> UIColor
  ) {
    self.init { trait in
      switch trait.userInterfaceStyle {
      case .light, .unspecified:
        lightColor()
      case .dark:
        darkColor()
      @unknown default:
        lightColor()
      }
    }
  }
}
