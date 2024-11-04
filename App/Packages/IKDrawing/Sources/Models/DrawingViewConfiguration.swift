// Created by Igor Klyuzhev in 2024

import UIKit

public struct DrawingViewConfiguration {
  public var tool: DrawingTool?
  public var lineWidth: CGFloat
  public var color: UIColor

  public var selectedShape: GeometryObject? {
    guard case let .geometry(object) = tool else { return nil }
    return object
  }

  public var isEraser: Bool {
    tool == .eraser
  }

  public var canDraw: Bool {
    tool != nil
  }

  public var shouldOptimizeRenderingPath: Bool {
    !isGeometry
  }

  public var isGeometry: Bool {
    if case .geometry = tool {
      return true
    }
    return false
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
