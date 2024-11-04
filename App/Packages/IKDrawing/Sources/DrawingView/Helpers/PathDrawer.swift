// Created by Igor Klyuzhev in 2024

import UIKit

public enum PathDrawer {
  public static func makePathFor(
    _ object: GeometryObject,
    startPoint: CGPoint,
    endPoint: CGPoint,
    lineWidth: CGFloat
  ) -> UIBezierPath {
    switch object {
    case .triangle:
      let path = UIBezierPath()
      let topLeftPoint = startPoint
      let bottomRightPoint = endPoint

      let bottomLeftTrianglePoint = CGPoint(
        x: topLeftPoint.x,
        y: bottomRightPoint.y
      )
      let bottomRightTrianglePoint = bottomRightPoint
      let topPoint = CGPoint(
        x: (bottomRightPoint.x + topLeftPoint.x) / 2,
        y: topLeftPoint.y
      )
      path.move(to: topPoint)
      path.addLine(to: bottomRightTrianglePoint)
      path.addLine(to: bottomLeftTrianglePoint)
      path.addLine(to: topPoint)
      return path
    case .circle:
      let topLeftPoint = startPoint
      let bottomRightPoint = endPoint

      let rect = CGRect(
        x: topLeftPoint.x,
        y: topLeftPoint.y,
        width: bottomRightPoint.x - topLeftPoint.x,
        height: bottomRightPoint.y - topLeftPoint.y
      )
      return UIBezierPath(ovalIn: rect)
    case .square:
      let topLeftPoint = startPoint
      let bottomRightPoint = endPoint

      let rect = CGRect(
        x: topLeftPoint.x,
        y: topLeftPoint.y,
        width: bottomRightPoint.x - topLeftPoint.x,
        height: bottomRightPoint.y - topLeftPoint.y
      )
      return UIBezierPath(rect: rect)
    case .arrow:
      let start = startPoint
      let end = endPoint

      let vector = CGPoint(
        x: end.x - start.x,
        y: end.y - start.y
      )
      let startEndAngle: CGFloat
      if abs(vector.x) < 1.0e-7 {
        startEndAngle = vector.y < 0 ? -CGFloat.pi / 2.0 : CGFloat.pi / 2.0
      } else {
        startEndAngle = atan(vector.y / vector.x) + (vector.x < 0 ? CGFloat.pi : 0)
      }

      let arrowAngle = CGFloat.pi * 1.0 / 6.0
      let percentLength = (lineWidth / 60.0)
      let arrowLength = percentLength * sqrt(vector.x * vector.x + vector.y * vector.y)

      let arrowLine1 = CGPoint(
        x: end.x + arrowLength * cos(CGFloat.pi - startEndAngle + arrowAngle),
        y: end.y - arrowLength * sin(CGFloat.pi - startEndAngle + arrowAngle)
      )
      let arrowLine2 = CGPoint(
        x: end.x + arrowLength * cos(CGFloat.pi - startEndAngle - arrowAngle),
        y: end.y - arrowLength * sin(CGFloat.pi - startEndAngle - arrowAngle)
      )

      let path = UIBezierPath()
      path.move(to: start)
      path.addLine(to: end)

      path.move(to: end)
      path.addLine(to: arrowLine1)

      path.move(to: end)
      path.addLine(to: arrowLine2)

      return path
    case .line:
      let path = UIBezierPath()
      path.move(to: startPoint)
      path.addLine(to: endPoint)
      return path
    }
  }
}
