// Created by Igor Klyuzhev in 2024

import UIKit

final class FrameModel {
  private static let queue = DispatchQueue(label: "FrameModel.queue", qos: .default)

  private var _image: UIImage?
  private let uuid: UUID
  private let path: String?

  var image: UIImage? {
    if let image = _image {
      return image
    } else if let path,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path))
    {
      return UIImage(data: data)
    } else {
      return nil
    }
  }

  init(image: UIImage?) {
    uuid = UUID()
    _image = image

    guard let image else {
      self.path = nil
      return
    }
    let path = NSTemporaryDirectory() + "/drawing_\(uuid.hashValue).frame"
    self.path = path
    FrameModel.queue.asyncAfter(deadline: .now() + 5) {
      if let data = image.pngData() as? NSData {
        try? data.write(toFile: path)
        DispatchQueue.main.async {
          self._image = nil
        }
      }
    }
  }

  deinit {
    guard let path else { return }
    try? FileManager.default.removeItem(atPath: path)
  }
}
