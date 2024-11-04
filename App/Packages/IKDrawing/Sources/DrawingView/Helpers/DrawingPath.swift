// Created by Igor Klyuzhev in 2024

import UIKit

final class DrawingPath: UIBezierPath {
  private var points = [CGPoint]()

  convenience init(withPoints points: [CGPoint]) {
    self.init()
    self.points = points
    lineCapStyle = .round
  }

  override func move(to point: CGPoint) {
    points.removeAll()
    points.append(point)
    super.move(to: point)
  }

  override func addLine(to point: CGPoint) {
    points.append(point)
    super.addLine(to: point)
  }

  override func addCurve(to endPoint: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
    points.append(endPoint)
    super.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
  }

  override func addQuadCurve(to endPoint: CGPoint, controlPoint: CGPoint) {
    points.append(endPoint)
    super.addQuadCurve(to: endPoint, controlPoint: controlPoint)
  }
}

extension DrawingPath {
  func smoothPath(_ granularity: Int = 20) -> UIBezierPath {
    var points = points
    if points.count < 4 {
      let newPath = UIBezierPath()

      if points.count > 0 {
        for index in 0 ..< points.count {
          if index == 0 {
            newPath.move(to: points[index])
          } else {
            newPath.addLine(to: points[index])
          }
        }
      }

      return newPath
    }

    points.insert(points[0], at: 0)
    points.append(points.last!)

    let newPath = UIBezierPath()
    newPath.move(to: points[0])

    for pointIndex in 1 ... points.count - 3 {
      let point0 = points[pointIndex - 1]
      let point1 = points[pointIndex]
      let point2 = points[pointIndex + 1]
      let point3 = points[pointIndex + 2]

      for index in 1 ... granularity {
        let t = CGFloat(index) * (1.0 / CGFloat(granularity))
        let tt = CGFloat(t * t)
        let ttt = CGFloat(tt * t)

        var intermediatePoint = CGPoint()

        let xt = (point2.x - point0.x) * t
        let xtt = (2 * point0.x - 5 * point1.x + 4 * point2.x - point3.x) * tt
        let xttt = (3 * point1.x - point0.x - 3 * point2.x + point3.x) * ttt
        intermediatePoint.x = 0.5 * (2 * point1.x + xt + xtt + xttt)
        let yt = (point2.y - point0.y) * t
        let ytt = (2 * point0.y - 5 * point1.y + 4 * point2.y - point3.y) * tt
        let yttt = (3 * point1.y - point0.y - 3 * point2.y + point3.y) * ttt
        intermediatePoint.y = 0.5 * (2 * point1.y + yt + ytt + yttt)
        newPath.addLine(to: intermediatePoint)
      }
      newPath.addLine(to: point2)
    }
    newPath.addLine(to: points.last!)
    newPath.lineCapStyle = .round
    return newPath
  }
}
