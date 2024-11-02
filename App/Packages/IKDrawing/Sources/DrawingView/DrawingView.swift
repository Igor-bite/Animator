// Created by Igor Klyuzhev in 2024

import IKUtils
import SnapKit
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
  private lazy var topLayer = DrawingTopLayer(
    lineWidth: config.lineWidth,
    strokeColor: config.color,
    isEraser: false
  )
  private lazy var eraserTopLayer = DrawingTopLayer(
    lineWidth: config.lineWidth,
    strokeColor: .white,
    isEraser: true
  )
  private var drawingImage: UIImage?
  private var drawingImageView = UIImageView()
  private lazy var renderer: UIGraphicsImageRenderer = {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    format.preferredRange = .standard
    format.opaque = false
    return UIGraphicsImageRenderer(size: bounds.size, format: format)
  }()

  init(controller: DrawingViewOutput) {
    self.controller = controller
    super.init(frame: .zero)
    setup()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    topLayer.frame = bounds
    topLayer.setNeedsDisplay()
    eraserTopLayer.frame = bounds
    eraserTopLayer.setNeedsDisplay()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup() {
    addSubviews(drawingImageView)
    drawingImageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    isOpaque = false
    clipsToBounds = true
    layer.addSublayer(topLayer)
    eraserTopLayer.isEraser = true
  }
}

// MARK: - DrawingViewInput

extension DrawingView: DrawingViewInput {
  func execute(command: DrawingCommand) {
    UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) { [weak self] in
      guard let self else { return }
      switch command {
      case let .addLayer(layer):
//        layersContainer.layer.insertSublayer(layer, below: topLayer)
        setNeedsDisplay()
      case let .removeLayer(layer):
//        layer.removeFromSuperlayer()
        setNeedsDisplay()
      }
    }
  }
}

// MARK: - Layers

extension DrawingView {
  private func updateTopLayer() {
    let pathLayer = DrawingPath(withPoints: pointsBuffer).smoothPath()
    let topLayer = config.isEraser ? eraserTopLayer : topLayer
    topLayer.lineWidth = config.lineWidth
    topLayer.strokeColor = config.color
    topLayer.path = pathLayer.cgPath
    topLayer.setNeedsDisplay()
  }

  private func flushTopLayer() {
    pointsBuffer.removeAll()
    clearTopLayer()
  }

  private func addCircleLayer(in rect: CGRect) {
    let shape = UIBezierPath(ovalIn: rect)
    addShapeLayer(shape, lineWidth: config.lineWidth, color: config.color)
  }

  private func addShapeLayer(_ shape: UIBezierPath, lineWidth: CGFloat, color: UIColor) {
    let imageSize = bounds.size

    drawingImage = renderer.image { ctx in
      ctx.cgContext.setBlendMode(.copy)
      ctx.cgContext.clear(CGRect(origin: .zero, size: imageSize))
      if let image = drawingImage {
        image.draw(at: .zero)
      }

      if config.isEraser {
        ctx.cgContext.setBlendMode(.clear)
        ctx.cgContext.setLineCap(.round)
        ctx.cgContext.setLineJoin(.round)
        ctx.cgContext.setLineWidth(lineWidth)
        ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
        ctx.cgContext.addPath(shape.cgPath)
        ctx.cgContext.drawPath(using: .stroke)
      } else {
        ctx.cgContext.setBlendMode(.normal)
        ctx.cgContext.setLineCap(.round)
        ctx.cgContext.setLineJoin(.round)
        ctx.cgContext.setLineWidth(lineWidth)
        ctx.cgContext.setStrokeColor(color.cgColor)
        ctx.cgContext.addPath(shape.cgPath)
        ctx.cgContext.drawPath(using: .stroke)
      }
      // TODO: extract drawing logic of path into separate object
    }

    drawingImageView.image = drawingImage
    // TODO: вернуть поддержку undo / redo с помощью сохранения промежуточных изображений слоёв
//    controller.commit(command: .addLayer(newShapeLayer))
  }

  private func clearTopLayer() {
    topLayer.path = nil
    topLayer.setNeedsDisplay()
    eraserTopLayer.path = nil
    eraserTopLayer.setNeedsDisplay()
  }
}

// MARK: - Touches handling

extension DrawingView {
  private func handleTouchStart(at location: CGPoint) {
    touchDownPoint = location
    pointsBuffer.append(location)
    if config.isEraser, drawingImageView.layer.mask == nil {
      drawingImageView.layer.mask = eraserTopLayer
    }
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
      addCircleLayer(
        in: CGRect(
          x: location.x,
          y: location.y,
          width: circleSize,
          height: circleSize
        )
      )
    } else {
      let pathLayer = DrawingPath(withPoints: pointsBuffer).smoothPath()
      addShapeLayer(
        pathLayer,
        lineWidth: config.lineWidth,
        color: config.color
      )
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
