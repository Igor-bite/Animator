// Created by Igor Klyuzhev in 2024

import UIKit

final class DrawingTopLayer: CALayer {
  var path: CGPath?
  var lineWidth: CGFloat
  var strokeColor: UIColor
  var tool: DrawingTool

  init(
    lineWidth: CGFloat,
    strokeColor: UIColor,
    tool: DrawingTool
  ) {
    self.lineWidth = lineWidth
    self.strokeColor = strokeColor
    self.tool = tool
    super.init()
    actions = [
      "onOrderIn": NSNull(),
      "onOrderOut": NSNull(),
      "sublayers": NSNull(),
      "contents": NSNull(),
      "bounds": NSNull(),
    ]
  }

  override init(layer: Any) {
    lineWidth = 20
    strokeColor = UIColor.black
    tool = .pen
    super.init(layer: layer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(in ctx: CGContext) {
    switch tool {
    case .pen:
      ctx.setLineWidth(lineWidth)
      ctx.setLineCap(.round)
      ctx.setLineJoin(.round)
      ctx.setStrokeColor(strokeColor.cgColor)
      if let path {
        ctx.addPath(path)
      }
      ctx.setBlendMode(.normal)
      ctx.drawPath(using: .stroke)
    case .brush:
      ctx.setBlendMode(.normal)
      ctx.setLineWidth(lineWidth / 2)
      ctx.setStrokeColor(strokeColor.cgColor)
      ctx.setShadow(offset: .zero, blur: lineWidth / 2, color: strokeColor.cgColor)

      for _ in 0 ..< 4 {
        if let path {
          ctx.addPath(path)
        }
        ctx.drawPath(using: .stroke)
      }
    case .eraser:
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
    case let .geometry(object):
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
