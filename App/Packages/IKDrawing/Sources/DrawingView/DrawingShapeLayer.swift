// Created by Igor Klyuzhev in 2024

import UIKit

public class DrawingShapeLayer: CAShapeLayer {
  override init() {
    super.init()
    lineCap = CAShapeLayerLineCap.round
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
