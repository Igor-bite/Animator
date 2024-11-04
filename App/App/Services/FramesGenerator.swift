// Created by Igor Klyuzhev in 2024

import IKDrawing
import UIKit

final class FramesGenerator {
  private let renderingQueue = DispatchQueue(
    label: "FramesGenerator.renderingQueue",
    qos: .userInteractive,
    attributes: .concurrent
  )
  private let mainBGQueue = DispatchQueue(
    label: "FramesGenerator.mainBGQueue",
    qos: .userInteractive,
    attributes: .concurrent
  )
  private let shapes: [GeometryObject] = [
    .circle,
    .square,
    .triangle,
  ]
  private var workItem: DispatchWorkItem?

  var drawingRect: CGRect?
  var previewSize: CGSize?
  var config: DrawingViewConfiguration?

  func generateFrames(
    count: Int,
    completion: @escaping ([FrameModel]) -> Void
  ) {
    let workitem = DispatchWorkItem { [weak self] in
      guard let self else {
        assertionFailure()
        completion([])
        return
      }
      let shape = getShape()

      var startSize = getInitialSize()
      var startOrigin = getInitialOrigin(for: startSize)

      var endSize = getTargetSize()
      var endOrigin = getTargetOrigin(for: endSize)

      var frames = [FrameModel](
        repeating: FrameModel(
          image: nil,
          previewSize: .zero
        ),
        count: count
      )

      let stepsCountForAnimation = 10
      var chunkStart = 0
      let group = DispatchGroup()

      while chunkStart < count {
        guard let workItem = self.workItem,
              !workItem.isCancelled
        else { return }
        let renderer = makeRenderer()
        let stepsCount = min(stepsCountForAnimation, count - chunkStart)
        group.enter()
        renderingQueue.async { [chunkStart, renderer, startSize, startOrigin, endSize, endOrigin, stepsCountForAnimation, shape] in
          let diffX = endOrigin.x - startOrigin.x
          let diffY = endOrigin.y - startOrigin.y

          let diffWidth = endSize.width - startSize.width
          let diffHeight = endSize.height - startSize.height

          let xStep = diffX / CGFloat(stepsCountForAnimation)
          let yStep = diffY / CGFloat(stepsCountForAnimation)
          let widthStep = diffWidth / CGFloat(stepsCountForAnimation)
          let heightStep = diffHeight / CGFloat(stepsCountForAnimation)

          for i in 0 ..< stepsCount {
            let rect = CGRect(
              origin: CGPoint(
                x: startOrigin.x + xStep * CGFloat(i),
                y: startOrigin.y + yStep * CGFloat(i)
              ),
              size: CGSize(
                width: startSize.width + widthStep * CGFloat(i),
                height: startSize.height + heightStep * CGFloat(i)
              )
            )
            let frame = self.generateFrame(
              object: shape,
              rect: rect,
              renderer: renderer
            )
            frames[chunkStart + i] = frame
          }
          group.leave()
        }
        chunkStart += stepsCountForAnimation
        startOrigin = endOrigin
        startSize = endSize
        endSize = getTargetSize()
        endOrigin = getTargetOrigin(for: endSize)
      }

      group.notify(queue: .main) {
        completion(frames)
      }
    }
    workItem = workitem
    mainBGQueue.async(execute: workitem)
  }

  func cancel() {
    workItem?.cancel()
    workItem = nil
  }

  private func generateFrame(
    object: GeometryObject,
    rect: CGRect,
    renderer: UIGraphicsImageRenderer
  ) -> FrameModel {
    guard let config else { return FrameModel(image: nil, previewSize: .zero) }

    let path = PathDrawer.makePathFor(
      object,
      startPoint: rect.startPoint,
      endPoint: rect.endPoint,
      lineWidth: config.lineWidth
    )

    let image = renderer.image { ctx in
      ctx.cgContext.setBlendMode(.normal)
      ctx.cgContext.setLineCap(.round)
      ctx.cgContext.setLineJoin(.round)
      ctx.cgContext.setLineWidth(config.lineWidth)
      ctx.cgContext.setStrokeColor(config.color.cgColor)
      ctx.cgContext.setFillColor(config.color.cgColor)
      ctx.cgContext.addPath(path.cgPath)
      ctx.cgContext.drawPath(using: .stroke)
    }

    return FrameModel(
      image: image,
      previewSize: previewSize ?? .zero
    )
  }

  private func getShape() -> GeometryObject {
    shapes.randomElement() ?? .circle
  }

  private func getInitialOrigin(for size: CGSize) -> CGPoint {
    guard let drawingRect else { return .zero }

    return generateCGPoint(
      fromX: drawingRect.minX,
      toX: drawingRect.maxX - size.width,
      fromY: drawingRect.minY,
      toY: drawingRect.maxY - size.height
    )
  }

  private func getTargetOrigin(for size: CGSize) -> CGPoint {
    guard let drawingRect else { return .zero }

    return generateCGPoint(
      fromX: drawingRect.minX,
      toX: drawingRect.maxX - size.width,
      fromY: drawingRect.minY,
      toY: drawingRect.maxY - size.height
    )
  }

  private func generateCGPoint(
    fromX: Double,
    toX: Double,
    fromY: Double,
    toY: Double
  ) -> CGPoint {
    CGPoint(
      x: Double.random(in: fromX ... toX),
      y: Double.random(in: fromY ... toY)
    )
  }

  private func getInitialSize() -> CGSize {
    generateSize()
  }

  private func getTargetSize() -> CGSize {
    generateSize()
  }

  private func generateSize() -> CGSize {
    let v = CGFloat.random(in: 10 ... 250)
    return CGSize(
      width: v,
      height: v
    )
  }

  private func makeRenderer() -> UIGraphicsImageRenderer {
    let format = UIGraphicsImageRendererFormat()
    format.scale = UIScreen.main.scale
    format.preferredRange = .standard
    format.opaque = false
    return UIGraphicsImageRenderer(size: drawingRect?.size ?? .zero, format: format)
  }
}

extension CGRect {
  fileprivate var startPoint: CGPoint {
    CGPoint(
      x: minX,
      y: minY
    )
  }

  fileprivate var endPoint: CGPoint {
    CGPoint(
      x: maxX,
      y: maxY
    )
  }
}
