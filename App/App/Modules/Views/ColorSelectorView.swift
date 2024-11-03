// Created by Igor Klyuzhev in 2024

import Combine
import IKUI
import IKUtils
import SnapKit
import UIKit

protocol ColorSelectorViewDelegate: AnyObject {
  func didSelect(color: UIColor, shouldClose: Bool)
}

final class ColorSelectorView: UIView {
  private let recentColorsBlurView: UIView = {
    let blurView = UIVisualEffectView()
    blurView.isUserInteractionEnabled = false
    blurView.clipsToBounds = true
    blurView.effect = UIBlurEffect(style: .systemUltraThinMaterialLight)
    return blurView
  }()

  private let colorSlidersBlurView: UIView = {
    let blurView = UIVisualEffectView()
    blurView.isUserInteractionEnabled = false
    blurView.clipsToBounds = true
    blurView.effect = UIBlurEffect(style: .systemUltraThinMaterialLight)
    return blurView
  }()

  private let mainColors = [
    Colors.Palette.white,
    Colors.Palette.red,
    Colors.Palette.black,
    Colors.Palette.blue,
    Colors.Palette.gray,
    UIColor.green,
  ]

  private let recentColorsContainerStack = {
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
      self?.isColorSlidersVisible.toggle()
      self?.updatePalletteVisibility()
    }
    return view
  }()

  private lazy var redColorSlider = ColorSliderWithInput(
    delegate: self,
    initialValue: customColor.rgba.red,
    color: .red
  )
  private lazy var greenColorSlider = ColorSliderWithInput(
    delegate: self,
    initialValue: customColor.rgba.green,
    color: .green
  )
  private lazy var blueColorSlider = ColorSliderWithInput(
    delegate: self,
    initialValue: customColor.rgba.blue,
    color: .blue
  )

  private let colorSlidersContainerStack = {
    let view = UIStackView()
    view.axis = .vertical
    view.spacing = 16
    view.distribution = .equalSpacing
    return view
  }()

  private var isColorSlidersVisible = false
  private var bag = CancellableBag()
  private var initialFrame: CGRect = .zero

  private var customColor: UIColor

  override var intrinsicContentSize: CGSize {
    let recentColorsSize = recentColorsContainerStack.intrinsicContentSize.inset(by: UIEdgeInsets(allSidesEqualTo: -16))
    let slidersColorSlidersSize = colorSlidersContainerStack.intrinsicContentSize.inset(by: UIEdgeInsets(allSidesEqualTo: -16))
    return CGSize(
      width: recentColorsSize.width,
      height: recentColorsSize.height + 16 + slidersColorSlidersSize.height
    )
  }

  weak var delegate: ColorSelectorViewDelegate?

  init(initialColor: UIColor) {
    customColor = initialColor
    super.init(frame: .zero)
    setupUI()
    setupKeyboardObserver()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func updateColor(color: UIColor) {
    customColor = color
    redColorSlider.set(value: color.rgba.red)
    greenColorSlider.set(value: color.rgba.green)
    blueColorSlider.set(value: color.rgba.blue)
  }

  private func setupKeyboardObserver() {
    Publishers.keyboardFrame.sink { [weak self] kFrame in
      guard let self else { return }

      let isKeyboardVisible = kFrame.height > 0
      if isKeyboardVisible,
         transform == .identity
      {
        guard let window = UIWindow.keyWindow,
              let frame = colorSlidersBlurView.frame(in: window),
              transform == .identity
        else { return }

        let diff = max(0, frame.maxY - kFrame.minY)
        transform = CGAffineTransform(translationX: .zero, y: -diff)
      } else if !isKeyboardVisible {
        transform = .identity
      }
    }.store(in: bag)
  }

  private func setupUI() {
    colorSlidersBlurView.roundCorners([.topLeft, .topRight], radius: 12)
    updatePalletteVisibility()

    addSubviews(
      recentColorsBlurView,
      recentColorsContainerStack,
      colorSlidersBlurView,
      colorSlidersContainerStack
    )

    recentColorsBlurView.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      make.top.equalTo(recentColorsContainerStack.snp.top).offset(-16)
    }

    recentColorsContainerStack.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(16)
      make.trailing.bottom.equalToSuperview().offset(-16)
    }

    colorSlidersBlurView.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(recentColorsBlurView.snp.top).offset(-4)
      make.top.equalToSuperview()
    }

    colorSlidersContainerStack.snp.makeConstraints { make in
      make.leading.top.equalToSuperview().offset(16)
      make.bottom.trailing.equalTo(colorSlidersBlurView).offset(-16)
    }

    colorSlidersContainerStack.addArrangedSubviews([
      redColorSlider,
      greenColorSlider,
      blueColorSlider,
    ])

    setupRecentColorsStack()
  }

  private func setupRecentColorsStack() {
    recentColorsContainerStack.addArrangedSubview(palleteIcon)
    for color in mainColors {
      let image = ShapeImageGenerator.circleImage(color: color, size: .size32)
      let icon = TapIcon(
        size: .large(),
        icon: image,
        selectionType: .icon(image),
        renderingMode: .alwaysOriginal
      )
      recentColorsContainerStack.addArrangedSubview(icon)
      icon.addAction { [weak self] in
        self?.updateColor(color: color)
        self?.delegate?.didSelect(color: color, shouldClose: true)
      }
    }
  }

  private func updatePalletteVisibility() {
    UIView.animate(
      withDuration: 0.2,
      delay: 0.0,
      options: .curveEaseInOut
    ) { [weak self] in
      guard let self else { return }

      if !isColorSlidersVisible {
        colorSlidersBlurView.alpha = 0
        colorSlidersBlurView.transform = CGAffineTransform(translationX: .zero, y: 16)
        colorSlidersContainerStack.alpha = 0
        colorSlidersContainerStack.transform = CGAffineTransform(translationX: .zero, y: 16)
        recentColorsBlurView.roundCorners(.allCorners, radius: 12)
      } else {
        colorSlidersBlurView.alpha = 1
        colorSlidersBlurView.transform = .identity
        colorSlidersContainerStack.alpha = 1
        colorSlidersContainerStack.transform = .identity
        recentColorsBlurView.roundCorners([.bottomLeft, .bottomRight], radius: 12)
      }
    }
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    if colorSlidersBlurView.frame.contains(point) {
      return isColorSlidersVisible
    } else if recentColorsBlurView.frame.contains(point) {
      return true
    }
    return super.point(inside: point, with: event)
  }
}

extension ColorSelectorView: ColorSliderDelegate {
  func valueUpdate(color: UIColor, _ value: CGFloat) {
    var newColor = customColor.rgba
    switch color {
    case .red:
      newColor.red = value
    case .green:
      newColor.green = value
    case .blue:
      newColor.blue = value
    default:
      assertionFailure()
    }
    customColor = newColor.uiColor
    delegate?.didSelect(color: customColor, shouldClose: false)
  }
}
