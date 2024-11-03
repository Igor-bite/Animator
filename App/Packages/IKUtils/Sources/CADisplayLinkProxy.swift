// Created by Igor Klyuzhev in 2024

import QuartzCore

public final class CADisplayLinkProxy {
  private var displaylink: CADisplayLink?

  public var handler: (() -> Void)?
  public var timestamp: TimeInterval? {
    displaylink?.timestamp
  }

  public init(fps: Int? = nil) {
    displaylink = CADisplayLink(target: self, selector: #selector(tick))
    displaylink?.add(to: .main, forMode: .common)
    if let intFps = fps {
      let fps = Float(intFps)
      displaylink?.preferredFrameRateRange = .init(minimum: fps, maximum: fps, preferred: fps)
    }
  }

  public func invalidate() {
    displaylink?.remove(from: .main, forMode: .common)
    displaylink?.invalidate()
    displaylink = nil
  }

  public func pause() {
    displaylink?.isPaused = true
  }

  public func resume() {
    displaylink?.isPaused = false
  }

  @objc
  private func tick() {
    handler?()
  }
}
