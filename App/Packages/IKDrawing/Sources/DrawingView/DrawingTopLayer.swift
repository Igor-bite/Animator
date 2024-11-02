// Created by Igor Klyuzhev in 2024

import UIKit

final class DrawingTopLayer: CALayer {
  var path: CGPath?
  var lineWidth: CGFloat
  var strokeColor: UIColor
  var isEraser: Bool

  init(
    lineWidth: CGFloat,
    strokeColor: UIColor,
    isEraser: Bool
  ) {
    self.lineWidth = lineWidth
    self.strokeColor = strokeColor
    self.isEraser = isEraser
    super.init()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(in ctx: CGContext) {
    if isEraser {
      ctx.setFillColor(UIColor.gray.cgColor)
      ctx.fill(bounds)

      ctx.setStrokeColor(UIColor.clear.cgColor)
      ctx.setFillColor(UIColor.white.cgColor)
      ctx.setLineWidth(lineWidth)
      ctx.setLineCap(.round)
      ctx.setLineJoin(.round)
      if let path {
        ctx.addPath(path)
      }
      ctx.setBlendMode(.sourceIn)
      ctx.drawPath(using: .fillStroke)
    } else {
      ctx.setLineWidth(lineWidth)
      ctx.setLineCap(.round)
      ctx.setLineJoin(.round)
      ctx.setStrokeColor(strokeColor.cgColor)
      if let path {
        ctx.addPath(path)
      }
      ctx.setBlendMode(.normal)
      ctx.drawPath(using: .stroke)
    }
  }
}
