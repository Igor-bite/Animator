// Created by Igor Klyuzhev in 2024

import UIKit

public enum ShapeImageGenerator {
  public static func circleImage(
    color: UIColor,
    size: CGSize
  ) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { ctx in
      ctx.cgContext.setFillColor(color.cgColor)

      let rectangle = CGRect(x: 0, y: 0, width: size.width, height: size.height)
      ctx.cgContext.addEllipse(in: rectangle)
      ctx.cgContext.drawPath(using: .fill)
    }
  }

  public static func circleImageWithBorder(
    color: UIColor,
    size: CGSize,
    borderColor: UIColor = Colors.accent,
    lineWidth: CGFloat = 2
  ) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { ctx in
      ctx.cgContext.setFillColor(color.cgColor)
      ctx.cgContext.setStrokeColor(borderColor.cgColor)
      ctx.cgContext.setLineWidth(lineWidth)

      let rectangle = CGRect(
        x: lineWidth / 2,
        y: lineWidth / 2,
        width: size.width - lineWidth,
        height: size.height - lineWidth
      )
      ctx.cgContext.addEllipse(in: rectangle)
      ctx.cgContext.drawPath(using: .fillStroke)
    }
  }
}
