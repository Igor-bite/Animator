// Created by Igor Klyuzhev in 2024

import UIKit

public enum Animations {
  public enum Button {
    public static let duration: TimeInterval = 0.12
    public static let scaleValue: CGFloat = 0.98
  }
}

extension UIView {
  public func setScaleState(
    duration: TimeInterval = Animations.Button.duration,
    scaleValue: CGFloat = Animations.Button.scaleValue,
    completion: (() -> Void)? = nil
  ) {
    UIView.animate(
      withDuration: duration,
      delay: 0.0,
      options: [.curveEaseIn, .beginFromCurrentState, .allowUserInteraction]
    ) {
      self.transform = CGAffineTransform(scaleX: scaleValue, y: scaleValue)
    } completion: { _ in
      completion?()
    }
  }

  public func setDefaultState(
    duration: TimeInterval = Animations.Button.duration,
    completion: (() -> Void)? = nil
  ) {
    if transform == .identity {
      setScaleState {
        self.animateToDefault(duration: duration, completion: completion)
      }
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
        self.animateToDefault(duration: duration, completion: completion)
      }
    }
  }

  private func animateToDefault(
    duration: TimeInterval = Animations.Button.duration,
    completion: (() -> Void)? = nil
  ) {
    UIView.animate(
      withDuration: duration,
      delay: 0.0,
      options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]
    ) {
      self.transform = .identity
    } completion: { _ in
      completion?()
    }
  }
}

extension UIView {
  @discardableResult
  public func autoLayout() -> Self {
    translatesAutoresizingMaskIntoConstraints = false
    return self
  }
}
