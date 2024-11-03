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

  private var recentColors = [
    Colors.Palette.white,
    Colors.Palette.black,
    Colors.Palette.gray,
    Colors.Palette.red,
    Colors.accent,
    Colors.Palette.blue,
  ]

  private let indexToRemove = 2

  private let recentColorsContainerStack = {
    let view = UIStackView()
    view.axis = .horizontal
    view.spacing = 16
    view.distribution = .fill
    return view
  }()

  private var colorIcons = [TapIcon]()

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
    fromColor: .clear,
    toColor: .red,
    inputPostfix: "%"
  )
  private lazy var greenColorSlider = ColorSliderWithInput(
    delegate: self,
    initialValue: customColor.rgba.green,
    fromColor: .clear,
    toColor: .green,
    inputPostfix: "%"
  )
  private lazy var blueColorSlider = ColorSliderWithInput(
    delegate: self,
    initialValue: customColor.rgba.blue,
    fromColor: .clear,
    toColor: .blue,
    inputPostfix: "%"
  )

  private let colorSlidersContainerStack = {
    let view = UIStackView()
    view.axis = .vertical
    view.spacing = 16
    view.distribution = .equalSpacing
    return view
  }()

  private let separatorView = {
    let separatorView = UIView()
    separatorView.backgroundColor = .black
    separatorView.snp.makeConstraints { make in
      make.width.equalTo(UIScreen.onePixel)
      make.height.equalTo(32)
    }
    return separatorView
  }()

  private var isColorSlidersVisible = false
  private var bag = CancellableBag()
  private var isSliderColorInstalled: Bool = false

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
    for (i, color) in recentColors.enumerated() {
      let image = ShapeImageGenerator.circleImage(color: color, size: .size32)
      let icon = TapIcon(
        size: .large(),
        icon: image,
        selectionType: .icon(image),
        renderingMode: .alwaysOriginal
      )
      colorIcons.append(icon)
      recentColorsContainerStack.addArrangedSubview(icon)
      if i == indexToRemove {
        recentColorsContainerStack.addArrangedSubview(separatorView)
      }
      icon.addAction { [weak self] in
        guard let self else { return }
        updateColor(color: color)
        delegate?.didSelect(color: color, shouldClose: true)
        pushNewColorToRecents(color: color, fromSlider: false)
      }
    }
    recentColorsContainerStack.setCustomSpacing(8, after: colorIcons[indexToRemove])
    recentColorsContainerStack.setCustomSpacing(8, after: separatorView)
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
        colorSlidersContainerStack.transform = .identity
        recentColorsBlurView.roundCorners([.bottomLeft, .bottomRight], radius: 12)
      }
    }

    UIView.animate(
      withDuration: 0.2,
      delay: 0.1,
      options: .curveEaseInOut
    ) { [weak self] in
      guard let self else { return }

      if isColorSlidersVisible {
        colorSlidersContainerStack.alpha = 1
      }
    }
  }

  private func pushNewColorToRecents(color: UIColor, fromSlider: Bool) {
    if fromSlider {
      if !isSliderColorInstalled {
        recentColors.remove(at: indexToRemove)
        recentColors.insert(color, at: .zero)
        isSliderColorInstalled = true
      } else {
        recentColors[0] = color
      }
    } else {
      var indexToRemove = indexToRemove
      if let index = recentColors.firstIndex(where: { $0 == color }) {
        guard index <= indexToRemove, index != 0 else { return }
        indexToRemove = index
      }
      recentColors.remove(at: indexToRemove)
      recentColors.insert(color, at: .zero)
      isSliderColorInstalled = false
    }
    updateRecentColorsStack()
  }

  private func updateRecentColorsStack() {
    for i in 0 ..< colorIcons.count {
      updateColorIcon(at: i)
    }
  }

  private func updateColorIcon(at index: Int) {
    guard let color = recentColors[safe: index],
          let icon = colorIcons[safe: index]
    else {
      assertionFailure()
      return
    }
    let image = ShapeImageGenerator.circleImage(color: color, size: .size32)
    icon.configure(
      icon: image,
      selectionType: .icon(image)
    )
    icon.addAction { [weak self] in
      guard let self else { return }
      updateColor(color: color)
      delegate?.didSelect(color: color, shouldClose: true)
      pushNewColorToRecents(color: color, fromSlider: false)
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
    pushNewColorToRecents(color: customColor, fromSlider: true)
    delegate?.didSelect(color: customColor, shouldClose: false)
  }
}
