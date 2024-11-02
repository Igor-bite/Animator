// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

protocol ColorSliderInput {
  func updateValue(_ value: CGFloat)
}

final class ColorSlider: UIView, ColorSliderInput {
  private lazy var gradientView = {
    let view = GradientView(
      direction: .horizontal(.zero, 1),
      colors: [.clear, color]
    )
    view.layer.cornerRadius = Constants.knobSize / 2
    return view
  }()

  private let knobView = {
    let view = UIView()
    view.layer.cornerRadius = Constants.knobSize / 2
    view.backgroundColor = Colors.background
    return view
  }()

  private lazy var knobColorView = {
    let view = UIView()
    view.layer.cornerRadius = (Constants.knobSize - 6) / 2
    view.backgroundColor = color
    return view
  }()

  let color: UIColor
  weak var delegate: ColorSliderDelegate?

  init(
    initialValue: CGFloat,
    color: UIColor
  ) {
    self.color = color
    super.init(frame: .zero)
    updateValue(initialValue)
    setupUI()
    setupGesture()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func updateValue(_ value: CGFloat) {
    let size = gradientView.bounds.size
    let diff = Constants.knobSize / 2 + (size.height - Constants.knobSize) / 2

    let xOffset = value * (size.width - diff * 2) - size.width / 2 + diff
    knobView.transform = CGAffineTransform(
      translationX: xOffset,
      y: .zero
    )
  }

  private func setupUI() {
    isUserInteractionEnabled = true
    layer.cornerRadius = Constants.knobSize / 2
    gradientView.layer.borderColor = UIColor.gray.cgColor
    gradientView.layer.borderWidth = UIScreen.onePixel

    addSubviews(gradientView, knobView)

    gradientView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    knobView.snp.makeConstraints { make in
      make.centerX.centerY.equalToSuperview()
      make.height.width.equalTo(Constants.knobSize)
    }

    knobView.addSubview(knobColorView)
    knobColorView.snp.makeConstraints { make in
      make.leading.top.equalToSuperview().offset(3)
      make.trailing.bottom.equalToSuperview().offset(-3)
    }
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
      let size = gradientView.bounds.size
      let diff = Constants.knobSize / 2 + (size.height - Constants.knobSize) / 2

      let location = gestureRecognizer.location(in: self).offsetBy(
        dx: -size.width / 2 - Constants.knobSize / 2,
        dy: .zero
      )
      let xOffset = clamp(
        location.x,
        min: -size.width / 2 + diff,
        max: size.width / 2 - diff
      )
      knobView.transform = CGAffineTransform(
        translationX: xOffset,
        y: .zero
      )
      let value = (xOffset + size.width / 2 - diff) / (size.width - diff * 2)
      knobColorView.backgroundColor = color.withAlphaComponent(value)
      delegate?.valueUpdate(value)
    default:
      break
    }
  }

  override func point(
    inside point: CGPoint,
    with event: UIEvent?
  ) -> Bool {
    let area = knobView.frame
    return area.contains(point)
  }
}

extension ColorSlider: UIGestureRecognizerDelegate {
  override func gestureRecognizerShouldBegin(
    _ gestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    let location = gestureRecognizer.location(in: self)
    let area = knobView.frame.inset(
      by: UIEdgeInsets(allSidesEqualTo: -16)
    )
    return area.contains(location)
  }
}

private enum Constants {
  static let knobSize = 28.0
}
