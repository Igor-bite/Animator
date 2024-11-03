// Created by Igor Klyuzhev in 2024

import UIKit

public enum Colors {
  public static let accent = UIColor(hex: "#A8DB10FF")
  public static let background = UIColor(light: Palette.white, dark: Palette.black)
  public static let foreground = UIColor(light: Palette.black, dark: Palette.white)
  public static let disabled = Palette.gray

  public enum Palette {
    public static let white = UIColor(hex: "#FFFFFFFF")
    public static let black = UIColor(hex: "#000000FF")
    public static let blue = UIColor(hex: "#1976D2FF")
    public static let red = UIColor(hex: "#FF3D00FF")
    public static let gray = UIColor(hex: "#8B8B8BFF")
  }
}
