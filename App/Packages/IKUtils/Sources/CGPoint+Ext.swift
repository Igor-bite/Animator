// Created by Igor Klyuzhev in 2024

import CoreGraphics
import Foundation

extension CGPoint {
  public func movingX(by value: CGFloat) -> CGPoint {
    CGPoint(x: x + value, y: y)
  }

  public func movingY(by value: CGFloat) -> CGPoint {
    CGPoint(x: x, y: y + value)
  }

  public var length: CGFloat {
    sqrt(x * x + y * y)
  }

  public func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
    CGPoint(x: x + dx, y: y + dy)
  }
}

public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  CGPoint(
    x: lhs.x + rhs.x,
    y: lhs.y + rhs.y
  )
}

public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  CGPoint(
    x: lhs.x - rhs.x,
    y: lhs.y - rhs.y
  )
}

public prefix func - (rhs: CGPoint) -> CGPoint {
  CGPoint(x: -rhs.x, y: -rhs.y)
}

public func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
  CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

public func * (lhs: CGFloat, rhs: CGPoint) -> CGPoint {
  rhs * lhs
}

public func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
  CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}

public func - (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
  CGPoint(x: lhs.x - rhs, y: lhs.y - rhs)
}
