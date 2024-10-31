// Created by Igor Klyuzhev in 2024

import UIKit

extension UIWindow {
  public static var size: CGSize {
    keyWindow?.bounds.size ?? .zero
  }

  public static var safeAreaInsets: UIEdgeInsets {
    keyWindow?.safeAreaInsets ?? .zero
  }

  public static var keyWindow: UIWindow? {
    UIApplication
      .shared
      .connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.sceneKeyWindow }
      .last
  }

  public static var isPortraitOrientation: Bool {
    guard let window = keyWindow else {
      return UIDevice.current.orientation.isPortrait
    }

    return window.frame.size.width < window.frame.size.height
  }

  public static var isLandscapeOrientation: Bool {
    if let window = UIWindow.keyWindow {
      let isLandscape: Bool
      let orientation = UIDevice.current.orientation

      if orientation.isValidInterfaceOrientation {
        isLandscape = orientation.isLandscape
      } else {
        let interfaceOrientation = window.windowScene?.interfaceOrientation
        isLandscape = interfaceOrientation == .landscapeLeft || interfaceOrientation == .landscapeRight
      }

      return isLandscape
    } else {
      assertionFailure("Can't check isLandscapeOrientation")
      return false
    }
  }

  public static func checkProgrammaticLandscape() -> Bool {
    if let window = UIWindow.keyWindow {
      let isPortrait: Bool
      let orientation = UIDevice.current.orientation

      if orientation.isValidInterfaceOrientation {
        isPortrait = orientation.isPortrait
      } else {
        let interfaceOrientation = window.windowScene?.interfaceOrientation
        isPortrait = interfaceOrientation == .portrait || interfaceOrientation == .portraitUpsideDown
      }

      let wideScreen = window.bounds.width > window.bounds.height
      let result = isPortrait && wideScreen
      return result
    } else {
      assertionFailure("Can't check window")
      return false
    }
  }
}

extension UIWindowScene {
  public var sceneKeyWindow: UIWindow? {
    if #available(iOS 15.0, *) {
      return keyWindow
    } else {
      return windows.first(where: { $0.isKeyWindow })
    }
  }
}
