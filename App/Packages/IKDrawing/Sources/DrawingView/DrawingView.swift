// Created by Igor Klyuzhev in 2024

import UIKit

protocol DrawingViewInput: AnyObject {
  func execute(command: DrawingCommand)
}

protocol DrawingViewOutput {
  var config: DrawingViewConfiguration { get }

  func commit(command: DrawingCommand)
  func clearRedoHistory()
}

final class DrawingView: UIView {
  private var config: DrawingViewConfiguration {
    controller.config
  }

  private let controller: DrawingViewOutput

  private var touchDownPoint: CGPoint?
  private var pointsBuffer = [CGPoint]()
  private var topLayer = CAShapeLayer()

  init(controller: DrawingViewOutput) {
    self.controller = controller
    super.init(frame: .zero)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup() {
    topLayer.fillColor = nil
    layer.masksToBounds = true
    layer.addSublayer(topLayer)
  }
}

// MARK: - DrawingViewInput

extension DrawingView: DrawingViewInput {
  func execute(command: DrawingCommand) {
    switch command {
    case let .addLayer(layer):
      self.layer.insertSublayer(layer, below: topLayer)
      setNeedsDisplay()
    case let .removeLayer(layer):
      layer.removeFromSuperlayer()
      setNeedsDisplay()
    }
  }
}

// MARK: - Layers

extension DrawingView {
  private func updateTopLayer() {
    let pathLayer = DrawingPath(withPoints: pointsBuffer).smoothPath()
    topLayer.lineWidth = config.lineWidth

    let strokeColor = config.color
    topLayer.strokeColor = strokeColor.cgColor
    topLayer.fillColor = nil
    topLayer.contentsScale = UIScreen.main.scale

    topLayer.path = pathLayer.cgPath
  }

  private func flushTopLayer() {
    pointsBuffer.removeAll()
    clearTopLayer()
    setNeedsDisplay()
    layer.setNeedsDisplay()
  }

  private func addCircleLayer(in rect: CGRect) {
    let shape = UIBezierPath(ovalIn: rect)
    addShapeLayer(shape, lineWidth: config.lineWidth, color: config.color)
  }

  private func addShapeLayer(_ shape: UIBezierPath, lineWidth: CGFloat, color: UIColor) {
    let newShapeLayer = DrawingShapeLayer()
    newShapeLayer.path = shape.cgPath
    newShapeLayer.lineWidth = lineWidth
    newShapeLayer.strokeColor = color.cgColor
    newShapeLayer.fillColor = nil
    newShapeLayer.contentsScale = UIScreen.main.scale
    layer.insertSublayer(newShapeLayer, below: topLayer)
    newShapeLayer.setNeedsDisplay()
    controller.commit(command: .addLayer(newShapeLayer))
  }

  private func clearTopLayer() {
    topLayer.path = nil
  }
}

// MARK: - Touches handling

extension DrawingView {
  private func handleTouchStart(at location: CGPoint) {
    touchDownPoint = location
    pointsBuffer.append(location)
    updateTopLayer()
    controller.clearRedoHistory()
  }

  private func handleTouchMoved(to location: CGPoint) {
    pointsBuffer.append(location)
    updateTopLayer()
  }

  private func handleTouchEnded(at location: CGPoint, touchSize: CGFloat) {
    if pointsBuffer.count == 1 {
      let circleSize = touchSize * 2

      // MARK: Add circle shape layer

      addCircleLayer(
        in: CGRect(
          x: location.x,
          y: location.y,
          width: circleSize,
          height: circleSize
        )
      )
    } else {
      // MARK: Add bezier path shape layer

      let pathLayer = DrawingPath(withPoints: pointsBuffer).smoothPath()
      addShapeLayer(pathLayer, lineWidth: config.lineWidth, color: config.color)
    }

    flushTopLayer()
  }

  override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let touchPoint = touch.preciseLocation(in: self)
    handleTouchStart(at: touchPoint)
  }

  override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let superview,
          let touch = touches.first
    else {
      assertionFailure()
      return
    }

    let touchPoint = touch.preciseLocation(in: self)
    let rawPoint = touch.preciseLocation(in: superview) // TODO: check
    if frame.contains(rawPoint) == false {
      touchesEnded(touches, with: event)
      return
    }

    handleTouchMoved(to: touchPoint)
  }

  override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let touchPoint = touch.preciseLocation(in: self)

    handleTouchEnded(at: touchPoint, touchSize: touch.majorRadius)
  }

  override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchesEnded(touches, with: event)
  }
}
