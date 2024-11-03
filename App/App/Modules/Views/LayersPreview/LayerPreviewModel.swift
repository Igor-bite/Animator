// Created by Igor Klyuzhev in 2024

import UIKit

struct LayerPreviewModel: Hashable {
  let frameId: UUID
  let previewImage: UIImage

  init(frameId: UUID, previewImage: UIImage) {
    self.frameId = frameId
    self.previewImage = previewImage
  }

  init(frame: FrameModel) {
    self.init(
      frameId: frame.uuid,
      previewImage: frame.previewImage ?? frame.image ?? UIImage()
    )
  }
}
