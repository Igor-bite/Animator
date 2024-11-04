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
  private var pointsBuffer = [CGPoint]() {
    didSet {
      _lastDrawingPath = nil
    }
  }

  private var processedPointsCount = 0

  private var _lastDrawingPath: UIBezierPath?
  private var drawingPath: UIBezierPath {
    if let _lastDrawingPath {
      return _lastDrawingPath
    }
    let path = makeDrawingPath()
    _lastDrawingPath = path
    return path
  }

  private lazy var topLayer = DrawingTopLayer(
    lineWidth: config.lineWidth,
    strokeColor: config.color,
    tool: config.tool ?? .pen
  )
  private lazy var eraserTopLayer = DrawingTopLayer(
    lineWidth: config.lineWidth,
    strokeColor: .white,
    tool: .eraser
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

  private var drawingGesturePipeline: DrawingGesturePipeline?
  private var previousStateSlice: DrawingSlice?

  lazy var imageSize = bounds.size

  init(controller: DrawingViewOutput) {
    self.controller = controller
    super.init(frame: .zero)
    setup()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    topLayer.frame = bounds
    eraserTopLayer.frame = bounds
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
    setupGestures()
  }

  private func setupGestures() {
    drawingGesturePipeline = DrawingGesturePipeline(
      drawingView: self,
      gestureView: self
    )
    drawingGesturePipeline?.gestureRecognizer?.shouldBegin = { [weak self] _ in
      self?.controller.config.canDraw ?? false
    }
    drawingGesturePipeline?.onDrawing = { [weak self] state, point in
      guard let self else { return }
      let touchPoint = point.location
      switch state {
      case .began:
        handleTouchStart(at: touchPoint)
      case .changed:
        handleTouchMoved(to: touchPoint)
      case .ended, .cancelled:
        handleTouchEnded(at: touchPoint)
      }
    }
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
    let topLayer = config.isEraser ? eraserTopLayer : topLayer
    topLayer.tool = config.tool ?? .pen
    topLayer.lineWidth = config.lineWidth
    topLayer.strokeColor = config.color
    topLayer.path = drawingPath.cgPath
    topLayer.setNeedsDisplay()
  }

  private func makeDrawingPath() -> UIBezierPath {
    guard let tool = config.tool else { return UIBezierPath() }
    switch tool {
    case .pen, .brush, .eraser:
      return DrawingPath(withPoints: pointsBuffer).smoothPath()
    case let .geometry(geometryObject):
      switch geometryObject {
      case .triangle:
        let path = UIBezierPath()
        guard let topLeftPoint = touchDownPoint,
              let bottomRightPoint = pointsBuffer.last
        else { return path }

        let bottomLeftTrianglePoint = CGPoint(
          x: topLeftPoint.x,
          y: bottomRightPoint.y
        )
        let bottomRightTrianglePoint = bottomRightPoint
        let topPoint = CGPoint(
          x: (bottomRightPoint.x + topLeftPoint.x) / 2,
          y: topLeftPoint.y
        )
        path.move(to: topPoint)
        path.addLine(to: bottomRightTrianglePoint)
        path.addLine(to: bottomLeftTrianglePoint)
        path.addLine(to: topPoint)
        return path
      case .circle:
        guard let topLeftPoint = touchDownPoint,
              let bottomRightPoint = pointsBuffer.last
        else { return UIBezierPath() }

        let rect = CGRect(
          x: topLeftPoint.x,
          y: topLeftPoint.y,
          width: bottomRightPoint.x - topLeftPoint.x,
          height: bottomRightPoint.y - topLeftPoint.y
        )
        return UIBezierPath(ovalIn: rect)
      case .square:
        guard let topLeftPoint = touchDownPoint,
              let bottomRightPoint = pointsBuffer.last
        else { return UIBezierPath() }

        let rect = CGRect(
          x: topLeftPoint.x,
          y: topLeftPoint.y,
          width: bottomRightPoint.x - topLeftPoint.x,
          height: bottomRightPoint.y - topLeftPoint.y
        )
        return UIBezierPath(rect: rect)
      case .arrow:
        guard let start = touchDownPoint,
              let end = pointsBuffer.last
        else { return UIBezierPath() }

        let vector = CGPoint(
          x: end.x - start.x,
          y: end.y - start.y
        )
        let startEndAngle: CGFloat
        if abs(vector.x) < 1.0e-7 {
          startEndAngle = vector.y < 0 ? -CGFloat.pi / 2.0 : CGFloat.pi / 2.0
        } else {
          startEndAngle = atan(vector.y / vector.x) + (vector.x < 0 ? CGFloat.pi : 0)
        }

        let arrowAngle = CGFloat.pi * 1.0 / 6.0
        let procentLength = (config.lineWidth / 60.0)
        let arrowLength = procentLength * sqrt(vector.x * vector.x + vector.y * vector.y)

        let arrowLine1 = CGPoint(
          x: end.x + arrowLength * cos(CGFloat.pi - startEndAngle + arrowAngle),
          y: end.y - arrowLength * sin(CGFloat.pi - startEndAngle + arrowAngle)
        )
        let arrowLine2 = CGPoint(
          x: end.x + arrowLength * cos(CGFloat.pi - startEndAngle - arrowAngle),
          y: end.y - arrowLength * sin(CGFloat.pi - startEndAngle - arrowAngle)
        )

        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)

        path.move(to: end)
        path.addLine(to: arrowLine1)

        path.move(to: end)
        path.addLine(to: arrowLine2)

        return path
      case .line:
        let path = UIBezierPath()
        guard let startPoint = touchDownPoint,
              let endPoint = pointsBuffer.last
        else { return path }

        path.move(to: startPoint)
        path.addLine(to: endPoint)
        return path
      }
    }
  }

  private func flushTopLayer() {
    pointsBuffer.removeAll()
    clearTopLayer()
  }

  private func addCircleLayer(in rect: CGRect) {
    let shape = UIBezierPath(ovalIn: rect)
    addShapeLayer(shape, lineWidth: config.lineWidth, color: config.color, drawingMode: .fillStroke)
  }

  private func addShapeLayer(
    _ shape: UIBezierPath,
    lineWidth: CGFloat,
    color: UIColor,
    drawingMode: CGPathDrawingMode = .stroke
  ) {
    guard let drawingTool = config.tool else { return }
    let imageSize = bounds.size

    let newImage = renderer.image { ctx in
      ctx.cgContext.setBlendMode(.copy)
      ctx.cgContext.clear(CGRect(origin: .zero, size: imageSize))
      if let image = drawingImage {
        image.draw(at: .zero)
      }

      switch drawingTool {
      case .pen, .geometry:
        ctx.cgContext.setBlendMode(.normal)
        ctx.cgContext.setLineCap(.round)
        ctx.cgContext.setLineJoin(.round)
        ctx.cgContext.setLineWidth(lineWidth)
        ctx.cgContext.setStrokeColor(color.cgColor)
        ctx.cgContext.setFillColor(color.cgColor)
        ctx.cgContext.addPath(shape.cgPath)
        ctx.cgContext.drawPath(using: drawingMode)
      case .brush:
        ctx.cgContext.setBlendMode(.normal)
        ctx.cgContext.setLineWidth(lineWidth / 2)
        ctx.cgContext.setStrokeColor(color.cgColor)
        ctx.cgContext.setFillColor(color.cgColor)
        ctx.cgContext.setShadow(offset: .zero, blur: lineWidth / 2, color: color.cgColor)

        for _ in 0 ..< 4 {
          ctx.cgContext.addPath(shape.cgPath)
          ctx.cgContext.drawPath(using: drawingMode)
        }
      case .eraser:
        ctx.cgContext.setBlendMode(.clear)
        ctx.cgContext.setLineCap(.round)
        ctx.cgContext.setLineJoin(.round)
        ctx.cgContext.setLineWidth(lineWidth)
        ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
        ctx.cgContext.setFillColor(UIColor.white.cgColor)
        ctx.cgContext.addPath(shape.cgPath)
        ctx.cgContext.drawPath(using: drawingMode)
      }
      // TODO: extract drawing logic of path into separate object
    }
    drawingImage = newImage
  }

  private func savePreviousDrawingState() {
    if let previousStateSlice {
      controller.commit(command: .slice(previousStateSlice))
      self.previousStateSlice = nil
    } else {
      controller.commit(command: .clearAll)
    }
  }

  private func clearTopLayer() {
    if config.isEraser {
      eraserTopLayer.path = nil
      eraserTopLayer.setNeedsDisplay()
    } else {
      topLayer.path = nil
      topLayer.setNeedsDisplay()
    }
  }
}

// MARK: - Touches handling

extension DrawingView {
  private func handleTouchStart(at location: CGPoint) {
    guard config.canDraw else { return }
    previousStateSlice = slice()
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
    if config.isGeometry,
       let touchDownPoint
    {
      pointsBuffer = [touchDownPoint, location]
    } else {
      pointsBuffer.append(location)
    }
    let pointsMaxCount = 4
    if config.shouldOptimizeRenderingPath,
       pointsBuffer.count == pointsMaxCount
    {
      addShapeLayer(
        drawingPath,
        lineWidth: config.lineWidth,
        color: config.color
      )
      processedPointsCount += pointsBuffer.count
      flushTopLayer()
      pointsBuffer.append(location)
    } else {
      updateTopLayer()
    }
  }

  private func handleTouchEnded(at location: CGPoint) {
    guard config.canDraw else { return }
    let circleSize = config.lineWidth / 2
    if pointsBuffer.count == 1, processedPointsCount == 0 {
      addCircleLayer(
        in: CGRect(
          x: location.x - circleSize / 2,
          y: location.y - circleSize / 2,
          width: circleSize,
          height: circleSize
        )
      )
    } else {
      addShapeLayer(
        drawingPath,
        lineWidth: config.lineWidth,
        color: config.color
      )
    }
    processedPointsCount = 0
    savePreviousDrawingState()
    flushTopLayer()
    controller.didEndDrawing()
  }
}
