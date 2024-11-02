// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

protocol ColorSelectorViewDelegate: AnyObject {
  func didRequestPallette()
  func didSelect(color: UIColor)
}

final class ColorSelectorView: UIView {
  private let blurView: UIView = {
    let blurView = UIVisualEffectView()
    blurView.isUserInteractionEnabled = false
    blurView.clipsToBounds = true
    blurView.effect = UIBlurEffect(style: .systemUltraThinMaterialLight)
    return blurView
  }()

  private let mainColors = [
    UIColor.white,
    UIColor(hex: "#FF3D00FF"),
    UIColor(hex: "#1C1C1CFF"),
    UIColor(hex: "#1976D2FF"),
  ]

  private let containerStack = {
    let view = UIStackView()
    view.axis = .horizontal
    view.spacing = 16
    view.distribution = .equalSpacing
    return view
  }()

  private lazy var palleteIcon = {
    let view = TapIcon(
      size: .large(),
      icon: Asset.palette.image,
      selectionType: .tint(Colors.accent)
    )
    view.addAction { [weak self] in
      self?.delegate?.didRequestPallette()
    }
    return view
  }()

  override var intrinsicContentSize: CGSize {
    containerStack.intrinsicContentSize.inset(by: UIEdgeInsets(allSidesEqualTo: -16))
  }

  weak var delegate: ColorSelectorViewDelegate?

  init() {
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    smoothCornerRadius = 12
    clipsToBounds = true
    addSubviews(blurView, containerStack)
    blurView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    containerStack.addArrangedSubview(palleteIcon)

    for color in mainColors {
      let image = ShapeImageGenerator.circleImage(color: color, size: .size32)
      let icon = TapIcon(
        size: .large(),
        icon: image,
        selectionType: .icon(image),
        renderingMode: .alwaysOriginal
      )
      containerStack.addArrangedSubview(icon)
      icon.addAction { [weak self] in
        self?.delegate?.didSelect(color: color)
      }
    }

    containerStack.snp.makeConstraints { make in
      make.leading.top.equalToSuperview().offset(16)
      make.trailing.bottom.equalToSuperview().offset(-16)
    }
  }
}
