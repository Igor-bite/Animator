// Created by Igor Klyuzhev in 2024

import IKUtils
import QuickLook
import UIKit

final class GIFExporter: NSObject {
  private let queue = DispatchQueue(label: "GIFExporter.queue")
  private var gifFileUrl: URL?
  private var quickLookDismissed: (() -> Void)?
  private var imageSize: CGSize
  private lazy var renderer = UIGraphicsImageRenderer(size: imageSize)

  @RWLocked
  var isCancelled = false

  init(imageSize: CGSize) {
    self.imageSize = imageSize
  }

  func export(
    frames: [FrameModel],
    fps: Int,
    exportCompletion: @escaping () -> Void,
    quickLookDismissed: @escaping () -> Void
  ) {
    isCancelled = false
    self.quickLookDismissed = quickLookDismissed
    gifFileUrl = nil

    queue.async {
      guard !self.isCancelled else { return }
      let totalFrames = frames.count
      let destinationFilename = "animation_\(UUID().uuidString).gif"
      let destinationURL = URL(
        fileURLWithPath: NSTemporaryDirectory()
      ).appendingPathComponent(destinationFilename)
      let fileDictionary = [
        kCGImagePropertyGIFDictionary: [
          kCGImagePropertyGIFLoopCount: 1,
        ],
      ]
      let frameDictionary = [
        kCGImagePropertyGIFDictionary: [
          kCGImagePropertyGIFDelayTime: 1.0 / Double(fps),
        ],
      ]

      guard let animatedGifFile = CGImageDestinationCreateWithURL(
        destinationURL as CFURL,
        UTType.gif.identifier as CFString,
        totalFrames,
        nil
      ) else {
        assertionFailure("error creating gif file")
        return
      }
      CGImageDestinationSetProperties(
        animatedGifFile,
        fileDictionary as CFDictionary
      )

      for frame in frames {
        guard !self.isCancelled else { return }
        guard let frameImage = frame.image?.cgImage ?? self.generateEmptyImage().cgImage else { continue }
        CGImageDestinationAddImage(
          animatedGifFile,
          frameImage,
          frameDictionary as CFDictionary
        )
      }

      guard !self.isCancelled else { return }
      if CGImageDestinationFinalize(animatedGifFile) {
        DispatchQueue.main.async {
          guard !self.isCancelled else { return }
          exportCompletion()
          self.gifFileUrl = destinationURL
          self.showQuickLook()
        }
      }
    }
  }

  private func generateEmptyImage() -> UIImage {
    renderer.image { _ in }
  }

  private func showQuickLook() {
    let qlPreviewController = QLPreviewController()
    qlPreviewController.dataSource = self
    qlPreviewController.delegate = self
    qlPreviewController.currentPreviewItemIndex = 0
    UIWindow.keyWindow?.rootViewController?.present(qlPreviewController, animated: true)
  }
}

extension GIFExporter: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    gifFileUrl == nil ? 0 : 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    guard let gifFileUrl else { return URL(fileURLWithPath: "") as QLPreviewItem }
    return gifFileUrl as QLPreviewItem
  }

  func previewControllerDidDismiss(_ controller: QLPreviewController) {
    DispatchQueue.main.async {
      self.quickLookDismissed?()
    }
  }
}
