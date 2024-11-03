// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

protocol FramesPlayerViewInput: AnyObject {
  func updateFrame(to image: UIImage?)
}

protocol FramesPlayerViewOutput: AnyObject {}

final class FramesPlayerView: UIView {
  private let controller: FramesPlayerViewOutput

  private lazy var currentFrameView = {
    let view = UIImageView()
    return view
  }()

  init(controller: FramesPlayerViewOutput) {
    self.controller = controller
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubviews(currentFrameView)

    currentFrameView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
}

extension FramesPlayerView: FramesPlayerViewInput {
  func updateFrame(to image: UIImage?) {
    currentFrameView.image = image
  }
}
