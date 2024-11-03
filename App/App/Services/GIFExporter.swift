// Created by Igor Klyuzhev in 2024

import QuickLook
import UIKit

final class GIFExporter {
  private let queue = DispatchQueue(label: "GIFExporter.queue")
  private var gifFileUrl: URL?

  func export(frames: [FrameModel], fps: Int) {
    gifFileUrl = nil

    queue.async {
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
        guard let frameImage = frame.image?.cgImage else { continue }
        CGImageDestinationAddImage(
          animatedGifFile,
          frameImage,
          frameDictionary as CFDictionary
        )
      }

      if CGImageDestinationFinalize(animatedGifFile) {
        DispatchQueue.main.async {
          self.gifFileUrl = destinationURL
          self.showQuickLook()
        }
      }
    }
  }

  private func showQuickLook() {
    let qlPreviewController = QLPreviewController()
    qlPreviewController.dataSource = self
    qlPreviewController.currentPreviewItemIndex = 0
    UIWindow.keyWindow?.rootViewController?.present(qlPreviewController, animated: true)
  }
}

extension GIFExporter: QLPreviewControllerDataSource {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    gifFileUrl == nil ? 0 : 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    guard let gifFileUrl else { return URL(fileURLWithPath: "") as QLPreviewItem }
    return gifFileUrl as QLPreviewItem
  }
}
