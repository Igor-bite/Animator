// Created by Igor Klyuzhev in 2024

import UIKit

public struct DrawingViewConfiguration {
  public var tool: DrawingTool?
  public var lineWidth: CGFloat
  public var color: UIColor

  public var isEraser: Bool {
    tool == .eraser
  }

  public var canDraw: Bool {
    tool != nil
  }

  public init(
    tool: DrawingTool?,
    lineWidth: CGFloat,
    color: UIColor
  ) {
    self.tool = tool
    self.lineWidth = lineWidth
    self.color = color
  }
}
