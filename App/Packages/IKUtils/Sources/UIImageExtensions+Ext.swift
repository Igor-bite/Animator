// Created by Igor Klyuzhev in 2024

import Foundation
import UIKit

extension UIImage {
  private static func delayForImage(at index: Int, source: CGImageSource) -> Double {
    let delay = 0.1
    guard let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil),
          let gifProperties =
          (cfProperties as NSDictionary)[kCGImagePropertyGIFDictionary] as? NSDictionary
    else {
      return delay
    }
    var delayObject = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double
    if delayObject == 0 {
      delayObject = gifProperties[kCGImagePropertyGIFDelayTime] as? Double
    }
    if let delayObject = delayObject, delayObject > 0 {
      return delayObject
    }
    return delay
  }

  public static func animatedImage(with data: CFData, decode: Bool = false) -> UIImage? {
    if decode {
      let options: [AnyHashable: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceShouldCache: true,
      ]
      return animatedImage(
        with: data,
        imageMaker: CGImageSourceCreateThumbnailAtIndex,
        options: options as CFDictionary
      )
    } else {
      return animatedImage(
        with: data,
        imageMaker: CGImageSourceCreateImageAtIndex,
        options: nil
      )
    }
  }

  private static func animatedImage(
    with data: CFData,
    imageMaker: (_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CGImage?,
    options: CFDictionary?
  ) -> UIImage? {
    guard let source = CGImageSourceCreateWithData(data, nil) else { return nil }
    let count = CGImageSourceGetCount(source)
    var images = [CGImage]()
    var delays = [Int]()

    for i in 0 ..< count {
      if let image = imageMaker(source, i, options) {
        images.append(image)
      }

      let delaySeconds = UIImage.delayForImage(at: i, source: source)
      delays.append(Int(delaySeconds * 1000.0))
    }
    guard images.count > 1 else { return images.first.map { UIImage(cgImage: $0) } }

    let duration = delays.reduce(0, +)
    let gcd = delays.gcd
    var frames = [UIImage]()
    for i in 0 ..< count {
      let frame = UIImage(cgImage: images[i])
      let frameCount = delays[i] / gcd
      frames += (0 ..< frameCount).map { _ in frame }
    }

    guard frames.count > 1 else { return frames.first }
    return UIImage.animatedImage(with: frames, duration: Double(duration) / 1000.0)
  }
}

extension Array where Element == Int {
  fileprivate var gcd: Int {
    guard !isEmpty else { return 0 }
    return reduce(0) { IKUtils.gcd($0, $1) }
  }
}

fileprivate func gcd(_ a: Int, _ b: Int) -> Int {
  var a = abs(a)
  var b = abs(b)
  var remainder = a % b
  while remainder != 0 {
    a = b
    b = remainder
    remainder = a % b
  }
  return b
}