// Created by Igor Klyuzhev in 2024

import UIKit

final class FrameModel {
  private static let queue = DispatchQueue(label: "FrameModel.queue", qos: .default)

  private var _image: UIImage?
  private let path: String?
  private let previewSize: CGSize
  private var saveToDiskWorkitem: DispatchWorkItem?

  let uuid: UUID

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

  var previewImage: UIImage?

  init(image: UIImage?, previewSize: CGSize) {
    self.previewSize = previewSize
    uuid = UUID()
    _image = image

    guard let image else {
      self.path = nil
      return
    }
    let path = NSTemporaryDirectory() + "/drawing_\(uuid.hashValue).frame"
    self.path = path
    renderPreview(for: image)
    scheduleSavingToDisk(image: image)
  }

  deinit {
    guard let path else { return }
    try? FileManager.default.removeItem(atPath: path)
  }

  func prefetchImage() {
    if let image = _image {
      scheduleSavingToDisk(image: image)
    } else if
      let path,
      let data = try? Data(contentsOf: URL(fileURLWithPath: path))
    {
      _image = UIImage(data: data)
    }
  }

  private func scheduleSavingToDisk(image: UIImage) {
    guard let path else { return }
    saveToDiskWorkitem?.cancel()
    saveToDiskWorkitem = nil

    let workItem = DispatchWorkItem {
      guard let data = image.pngData() as? NSData else { return }
      try? data.write(toFile: path)
      DispatchQueue.main.async {
        self._image = nil
      }
    }
    saveToDiskWorkitem = workItem
    FrameModel.queue.asyncAfter(deadline: .now() + 5, execute: workItem)
  }

  private func renderPreview(for image: UIImage) {
    FrameModel.queue.async {
      guard let image = image.cgImage else { return }
      let format = UIGraphicsImageRendererFormat()
      format.scale = UIScreen.main.scale
      format.preferredRange = .standard
      format.opaque = false
      let imageSize = self.previewSize
      let renderer = UIGraphicsImageRenderer(
        size: imageSize,
        format: format
      )
      let rect = CGRect(origin: .zero, size: imageSize)
      let previewImage = renderer.image { ctx in
        ctx.cgContext.translateBy(x: imageSize.width / 2.0, y: imageSize.height / 2.0)
        ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
        ctx.cgContext.translateBy(x: -imageSize.width / 2.0, y: -imageSize.height / 2.0)
        ctx.cgContext.translateBy(x: rect.minX, y: imageSize.height - rect.maxY)
        ctx.cgContext.draw(image, in: rect)
      }
      DispatchQueue.main.async {
        self.previewImage = previewImage
      }
    }
  }
}
