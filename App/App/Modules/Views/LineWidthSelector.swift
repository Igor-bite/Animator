// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

public protocol LineWidthSelectorDelegate: AnyObject {
  func valueUpdate(_ value: CGFloat)
  func released()
}

public final class LineWidthSelector: UIView {
  private lazy var shapeRenderer: UIGraphicsImageRenderer = {
    let format = UIGraphicsImageRendererFormat()
    format.scale = UIScreen.main.scale
    format.preferredRange = .standard
    format.opaque = false
    return UIGraphicsImageRenderer(size: size, format: format)
  }()

  private let size: CGSize
  private let shapeImageView = UIImageView()
  private let knobView = {
    let view = UIView()
    view.layer.cornerRadius = 32 / 2
    view.backgroundColor = UIColor.lightGray
    return view
  }()

  public weak var delegate: LineWidthSelectorDelegate?

  public init(
    size: CGSize = CGSize(
      width: 192,
      height: 32
    ),
    delegate: LineWidthSelectorDelegate,
    initialValue: CGFloat
  ) {
    self.size = size
    self.delegate = delegate
    super.init(frame: .zero)
    set(initialValue: initialValue)
    UIView.performWithoutAnimation {
      transform = CGAffineTransform(rotationAngle: -.pi / 2)
    }
    setupUI()
    renderShapeImage()
    setupGesture()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func set(initialValue: CGFloat) {
    let xOffset = initialValue * size.width - size.width / 2
    knobView.transform = CGAffineTransform(
      translationX: xOffset,
      y: .zero
    )
  }

  private func setupUI() {
    snp.makeConstraints { make in
      make.width.equalTo(size.width + 32)
      make.height.equalTo(size.height + 32)
    }

    addSubviews(shapeImageView, knobView)

    shapeImageView.snp.makeConstraints { make in
      make.leading.top.equalToSuperview().offset(16)
      make.trailing.bottom.equalToSuperview().offset(-16)
    }

    knobView.snp.makeConstraints { make in
      make.centerX.centerY.equalToSuperview()
      make.height.width.equalTo(32)
    }
  }

  private func renderShapeImage() {
    let path = generateMaskPath(
      size: size,
      leftRadius: 4.0,
      rightRadius: size.height / 2
    ).cgPath
    let shapeImage = shapeRenderer.image { ctx in
      let context = ctx.cgContext
      context.setLineCap(.round)
      context.setLineJoin(.round)
      context.setStrokeColor(UIColor.white.cgColor)
      context.setFillColor(UIColor.white.cgColor)
      context.addPath(path)

      let colors = [
        UIColor.white.cgColor,
        UIColor(hex: "#EAFFABFF").cgColor,
        UIColor(hex: "#9CCB0CFF").cgColor,
      ] as CFArray

      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let colorLocations: [CGFloat] = [0.0, 0.5, 1.0]

      let startPoint = CGPoint(x: .zero, y: size.height / 2)
      let endPoint = CGPoint(x: size.width, y: size.height / 2)

      guard let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: colors,
        locations: colorLocations
      ) else {
        assertionFailure()
        context.drawPath(using: .fillStroke)
        return
      }

      context.clip()

      context.drawLinearGradient(
        gradient,
        start: startPoint,
        end: endPoint,
        options: []
      )
      context.fillPath()
    }
    shapeImageView.image = shapeImage
  }

  private func generateMaskPath(
    size: CGSize,
    leftRadius: CGFloat,
    rightRadius: CGFloat
  ) -> UIBezierPath {
    let path = UIBezierPath()
    path.addArc(
      withCenter: CGPoint(x: leftRadius, y: size.height / 2.0),
      radius: leftRadius,
      startAngle: .pi * 0.5,
      endAngle: -.pi * 0.5,
      clockwise: true
    )
    path.addArc(
      withCenter: CGPoint(
        x: size.width - rightRadius,
        y: size.height / 2.0
      ),
      radius: rightRadius,
      startAngle: -.pi * 0.5,
      endAngle: .pi * 0.5,
      clockwise: true
    )
    path.close()
    return path
  }

  private func setupGesture() {
    let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
    addGestureRecognizer(gestureRecognizer)
    gestureRecognizer.delegate = self
  }

  @objc
  private func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
    switch gestureRecognizer.state {
    case .changed:
      let location = gestureRecognizer.location(in: self).offsetBy(
        dx: -size.width / 2 - 16,
        dy: .zero
      )
      let xOffset = clamp(
        location.x,
        min: -size.width / 2,
        max: size.width / 2 - 16
      )
      knobView.transform = CGAffineTransform(
        translationX: xOffset,
        y: .zero
      )
      delegate?.valueUpdate((xOffset + size.width / 2) / size.width)
    case .ended, .cancelled:
      delegate?.released()
    default:
      break
    }
  }

  override public func point(
    inside point: CGPoint,
    with event: UIEvent?
  ) -> Bool {
    let area = knobView.frame
    return area.contains(point)
  }
}

extension LineWidthSelector: UIGestureRecognizerDelegate {
  override public func gestureRecognizerShouldBegin(
    _ gestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    let location = gestureRecognizer.location(in: self)
    let area = knobView.frame.inset(
      by: UIEdgeInsets(allSidesEqualTo: -16)
    )
    return area.contains(location)
  }
}
