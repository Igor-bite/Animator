// Created by Igor Klyuzhev in 2024

import UIKit

public enum ShapeImageGenerator {
  public static func circleImage(
    color: UIColor,
    size: CGSize
  ) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { rendererContext in
      color.setFill()
      rendererContext.cgContext.fillEllipse(
        in: CGRect(origin: .zero, size: size)
      )
    }
  }
}
