// Created by Igor Klyuzhev in 2024

import UIKit

extension UIImage {
  public var roundedCorners: UIImage {
    let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: self.size)
    UIGraphicsBeginImageContextWithOptions(self.size, false, 1)

    UIBezierPath(
      roundedRect: rect,
      cornerRadius: self.size.height
    ).addClip()
    draw(in: rect)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    assert(image != nil)
    UIGraphicsEndImageContext()
    return image ?? UIImage()
  }

  public func scaledImage(toSize size: CGSize, scale: CGFloat = 0.0) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    self.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: size.width, height: size.height)))
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
  }

  public func resized(newWidth: CGFloat) -> UIImage {
    let scale = newWidth / self.size.width
    let newHeight = self.size.height * scale

    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))

    draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

    let image = UIGraphicsGetImageFromCurrentImageContext()
    assert(image != nil)
    UIGraphicsEndImageContext()
    return image ?? UIImage()
  }

  public func rounded(targetDimension dimension: CGFloat? = nil) -> UIImage {
    let minDimension = min(size.width, size.height)
    let dimension = dimension ?? minDimension

    guard
      size.width > 0,
      size.height > 0,
      dimension > 0
    else {
      return UIImage()
    }

    let circleRect = CGRect(
      origin: .zero,
      size: CGSize(
        width: dimension,
        height: dimension
      )
    )

    let sizeMultiplier = dimension / minDimension
    let imageDrawingSize = CGSize(
      width: size.width * sizeMultiplier,
      height: size.height * sizeMultiplier
    )
    let imageDrawingRect = CGRect(
      origin: CGPoint(
        x: circleRect.midX - imageDrawingSize.width / 2,
        y: circleRect.midY - imageDrawingSize.height / 2
      ),
      size: imageDrawingSize
    )

    UIGraphicsBeginImageContextWithOptions(circleRect.size, false, UIScreen.main.scale)

    UIBezierPath(ovalIn: circleRect).addClip()
    draw(in: imageDrawingRect)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    assert(image != nil)
    UIGraphicsEndImageContext()
    return image ?? UIImage()
  }

  public func blurredImage() -> UIImage? {
    guard let ciImg = CIImage(image: self) else { return nil }

    let context = CIContext()
    let clampFilter = CIFilter(name: "CIAffineClamp")
    clampFilter?.setDefaults()
    clampFilter?.setValue(ciImg, forKey: kCIInputImageKey)

    let blur = CIFilter(name: "CIGaussianBlur")
    blur?.setValue(clampFilter?.outputImage, forKey: kCIInputImageKey)
    blur?.setValue(20, forKey: kCIInputRadiusKey)

    if let blurred = blur?.outputImage, let cgImage = context.createCGImage(blurred, from: ciImg.extent) {
      return UIImage(cgImage: cgImage)
    } else {
      return nil
    }
  }
}
