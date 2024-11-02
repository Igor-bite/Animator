// Created by Igor Klyuzhev in 2024

import UIKit

final class DrawingSlice {
  private static let queue = DispatchQueue(label: "DrawingSlice.queue", qos: .default)

  private var _image: CGImage?
  private let uuid: UUID
  private let path: String

  let rect: CGRect
  var image: CGImage? {
    if let image = _image {
      return image
    } else if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
      return UIImage(data: data)?.cgImage
    } else {
      return nil
    }
  }

  init(image: CGImage, rect: CGRect) {
    uuid = UUID()

    _image = image
    self.rect = rect
    path = NSTemporaryDirectory() + "/drawing_\(uuid.hashValue).slice"

    DrawingSlice.queue.asyncAfter(deadline: .now() + 2) {
      let image = UIImage(cgImage: image)
      if let data = image.pngData() as? NSData {
        try? data.write(toFile: self.path)
        DispatchQueue.main.async {
          self._image = nil
        }
      }
    }
  }

  deinit {
    try? FileManager.default.removeItem(atPath: self.path)
  }
}
