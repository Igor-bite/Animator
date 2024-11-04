// Created by Igor Klyuzhev in 2024

import IKUtils
import SnapKit
import UIKit

protocol DrawingViewInput: AnyObject {
  var imageSize: CGSize { get }

  func execute(command: DrawingCommand, animated: Bool)
  func slice() -> DrawingSlice?
  func currentSketchImage() -> UIImage?
  func reset()
}

protocol DrawingViewOutput {
  var config: DrawingViewConfiguration { get }

  func commit(command: DrawingCommand)
  func clearRedoHistory()
  func didStartDrawing()
  func didEndDrawing()
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
  private var drawingImage: UIImage? {
    didSet {
      drawingImageView.image = drawingImage
    }
  }

  private var drawingImageView = UIImageView()
  private lazy var renderer: UIGraphicsImageRenderer = {
    let format = UIGraphicsImageRendererFormat()
    format.scale = UIScreen.main.scale
    format.preferredRange = .standard
    format.opaque = false
    return UIGraphicsImageRenderer(size: bounds.size, format: format)
  }()

  lazy var imageSize = bounds.size

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
  func execute(command: DrawingCommand, animated: Bool) {
    let action = { [weak self] in
      guard let self else { return }
      switch command {
      case let .slice(drawingSlice):
        applySlice(drawingSlice)
      case .clearAll:
        drawingImage = nil
      }
    }

    if animated {
      UIView.transition(
        with: self,
        duration: 0.2,
        options: .transitionCrossDissolve
      ) {
        action()
      }
    } else {
      action()
    }
  }

  func slice() -> DrawingSlice? {
    let rect = CGRect(x: .zero, y: .zero, width: imageSize.width, height: imageSize.height)
    guard let subImage = drawingImage?.cgImage else { return nil }

    return DrawingSlice(image: subImage, rect: rect)
  }

  func currentSketchImage() -> UIImage? {
    guard let image = drawingImage?.cgImage else { return nil }
    return UIImage(cgImage: image)
  }

  func reset() {
    drawingImage = nil
    flushTopLayer()
  }
}

// MARK: - Layers

extension DrawingView {
  private func applySlice(_ slice: DrawingSlice) {
    let imageSize = imageSize
    drawingImage = renderer.image { context in
      context.cgContext.clear(CGRect(origin: .zero, size: imageSize))
      guard let image = slice.image else {
        assertionFailure()
        return
      }
      context.cgContext.translateBy(x: imageSize.width / 2.0, y: imageSize.height / 2.0)
      context.cgContext.scaleBy(x: 1.0, y: -1.0)
      context.cgContext.translateBy(x: -imageSize.width / 2.0, y: -imageSize.height / 2.0)
      context.cgContext.translateBy(x: slice.rect.minX, y: imageSize.height - slice.rect.maxY)
      context.cgContext.draw(image, in: CGRect(origin: .zero, size: slice.rect.size))
    }
  }

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

    let newImage = renderer.image { ctx in
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
    if drawingImage == nil {
      controller.commit(command: .clearAll)
    } else if let slice = slice() {
      controller.commit(command: .slice(slice))
    }
    drawingImage = newImage
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
    guard config.canDraw else { return }
    touchDownPoint = location
    pointsBuffer.append(location)
    if config.isEraser, drawingImageView.layer.mask == nil {
      drawingImageView.layer.mask = eraserTopLayer
    }
    updateTopLayer()
    controller.clearRedoHistory()
    controller.didStartDrawing()
  }

  private func handleTouchMoved(to location: CGPoint) {
    guard config.canDraw else { return }
    pointsBuffer.append(location)
    updateTopLayer()
  }

  private func handleTouchEnded(at location: CGPoint, touchSize: CGFloat) {
    guard config.canDraw else { return }
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
    controller.didEndDrawing()
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
