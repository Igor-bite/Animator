// Created by Igor Klyuzhev in 2024

import UIKit

class ScalableButton: UIButton {
  public var scaleValue: CGFloat = 0.9

  override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    setScaleState(scaleValue: scaleValue)
  }

  override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    setScaleState(scaleValue: scaleValue)
  }

  override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    setDefaultState()
  }

  override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    setDefaultState()
  }
}

