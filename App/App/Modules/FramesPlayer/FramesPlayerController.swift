// Created by Igor Klyuzhev in 2024

import IKUtils
import UIKit

struct FramesPlayerConfig: Hashable {
  let fps: Int
}

protocol FramesPlayerInteractor {
  func configure(with frames: [FrameModel])
  func start()
  func stop()
}

final class FramesPlayerController {
  private var config: FramesPlayerConfig {
    didSet {
      guard config != oldValue else { return }
      displayLink = makeDisplayLink()
    }
  }

  private var frames = [FrameModel]()
  private var currentFrameIndex = 0
  private lazy var displayLink = makeDisplayLink()

  weak var view: FramesPlayerViewInput?

  init(
    config: FramesPlayerConfig
  ) {
    self.config = config
    displayLink.handler = { [weak self] in
      guard let self else { return }
      currentFrameIndex += 1
      if currentFrameIndex >= frames.count {
        currentFrameIndex = 0
      }
      updateFrame()
    }
  }

  private func makeDisplayLink() -> CADisplayLinkProxy {
    let dl = CADisplayLinkProxy(fps: config.fps)
    dl.pause()
    return dl
  }

  private func updateFrame() {
    view?.updateFrame(to: getImage(at: currentFrameIndex))
  }

  private func getImage(at index: Int) -> UIImage? {
    frames[safe: index]?.image
  }
}

extension FramesPlayerController: FramesPlayerInteractor {
  func configure(with frames: [FrameModel]) {
    self.frames = frames
    currentFrameIndex = 0
    updateFrame()
  }

  func start() {
    displayLink.resume()
  }

  func stop() {
    displayLink.pause()
    currentFrameIndex = 0
    updateFrame()
  }
}

extension FramesPlayerController: FramesPlayerViewOutput {}
