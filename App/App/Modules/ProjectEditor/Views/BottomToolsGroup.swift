// Created by Igor Klyuzhev in 2024

import Combine
import IKDrawing
import IKUI
import IKUtils
import SnapKit
import UIKit

protocol BottomToolsGroupInput {
  func updateColorSelector(isSelected: Bool)
  func updateColorSelector(color: UIColor)

  func updateShapeSelector(isSelected: Bool)
}

protocol BottomToolsGroupOutput: AnyObject {
  func didSelect(tool: DrawingTool)
  func didTapShapeSelector()
  func didTapColorSelector()
  func didSelectFPS(_ newValue: Int)
}

struct BottomToolsGroupModel {
  let selectedTool: DrawingTool?
  let selectedColor: UIColor
}

final class BottomToolsGroup: UIView, BottomToolsGroupInput {
  weak var output: BottomToolsGroupOutput?

  private lazy var drawingToolsButtons: SelectableIconsGroup = {
    let icons: [SelectableIconsGroupModel.IconModel] = [
      .init(
        id: DrawingTool.pen.id,
        icon: Asset.pencil.image,
        model: DrawingTool.pen
      ),
      .init(
        id: DrawingTool.brush.id,
        icon: Asset.brush.image,
        model: DrawingTool.brush
      ),
      .init(
        id: DrawingTool.eraser.id,
        icon: Asset.eraser.image,
        model: DrawingTool.eraser
      ),
    ]
    let model = SelectableIconsGroupModel(
      icons: icons,
      intiallySelectedId: model.selectedTool?.id ?? ""
    )
    let view = SelectableIconsGroup(model: model)
    view.delegate = self
    return view
  }()

  private let shapeSelectorButton = TapIcon(
    size: .large(),
    icon: Asset.shapes.image,
    selectionType: .tint(Colors.accent)
  )

  private lazy var colorSelectorButton = TapIcon(
    size: .large(),
    icon: ShapeImageGenerator.circleImage(
      color: model.selectedColor,
      size: .size32
    ),
    selectionType: .icon(
      ShapeImageGenerator
        .circleImageWithBorder(
          color: model.selectedColor,
          size: .size32
        )
    ),
    renderingMode: .alwaysOriginal
  )

  private let drawingContainerView = UIView()

  private lazy var fpsSlider = {
    let max = 30.0
    let min = 1.0
    let initial = 10.0
    let view = ColorSliderWithInput(
      delegate: self,
      initialValue: initial / max,
      fromColor: Colors.foreground,
      toColor: Colors.accent,
      inputPostfix: "FPS",
      multiplier: max,
      minValue: Int(min),
      maxValue: Int(max)
    )
    view.alpha = 0
    return view
  }()

  private let model: BottomToolsGroupModel
  private var bag = CancellableBag()

  init(model: BottomToolsGroupModel) {
    self.model = model
    super.init(frame: .zero)
    setupUI()
    setupActions()
    setupKeyboardObserver()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func updateColorSelector(isSelected: Bool) {
    colorSelectorButton.isSelected = isSelected
  }

  func updateColorSelector(color: UIColor) {
    let image = ShapeImageGenerator.circleImage(
      color: color,
      size: .size32
    )
    let selectedImage = ShapeImageGenerator.circleImageWithBorder(
      color: color,
      size: .size32
    )
    colorSelectorButton.configure(
      icon: image,
      selectionType: .icon(selectedImage)
    )
  }

  func updateShapeSelector(isSelected: Bool) {
    shapeSelectorButton.isSelected = isSelected
  }

  func updateShapeSelector(object: GeometryObject?) {
    if let image = object?.image {
      shapeSelectorButton.configure(
        icon: image,
        tint: Colors.accent
      )
      drawingToolsButtons.deselect()
    } else {
      shapeSelectorButton.configure(
        icon: Asset.shapes.image.withRenderingMode(.alwaysTemplate),
        tint: Colors.foreground
      )
    }
  }

  private func setupKeyboardObserver() {
    Publishers.keyboardFrame.sink { [weak self] kFrame in
      guard let self else { return }

      let isKeyboardVisible = kFrame.height > 0
      if isKeyboardVisible,
         transform == .identity
      {
        guard let window = UIWindow.keyWindow,
              let frame = fpsSlider.frame(in: window),
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
    snp.makeConstraints { make in
      make.height.equalTo(36)
    }

    addSubviews(drawingContainerView, fpsSlider)

    fpsSlider.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(32)
      make.trailing.equalToSuperview().offset(-32)
    }

    drawingContainerView.addSubviews(
      drawingToolsButtons,
      shapeSelectorButton,
      colorSelectorButton
    )

    let spacing = 16
    drawingContainerView.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.centerX.equalToSuperview()
    }

    drawingToolsButtons.snp.makeConstraints { make in
      make.leading.top.bottom.equalToSuperview()
    }

    shapeSelectorButton.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.leading.equalTo(drawingToolsButtons.snp.trailing).offset(spacing)
    }

    colorSelectorButton.snp.makeConstraints { make in
      make.trailing.top.bottom.equalToSuperview()
      make.leading.equalTo(shapeSelectorButton.snp.trailing).offset(spacing)
    }

    colorSelectorButton.layer.shadowColor = Colors.foreground.cgColor
    colorSelectorButton.layer.shadowRadius = 5
    colorSelectorButton.layer.shadowOffset = .init(squareDimension: 0)
    colorSelectorButton.layer.shadowOpacity = 0.4
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else { return }
    colorSelectorButton.layer.shadowColor = Colors.foreground.cgColor
    switch traitCollection.userInterfaceStyle {
    case .light, .unspecified:
      colorSelectorButton.layer.shadowOpacity = 0.3
    case .dark:
      colorSelectorButton.layer.shadowOpacity = 0.4
    @unknown default:
      colorSelectorButton.layer.shadowOpacity = 0.3
    }
  }

  private func setupActions() {
    shapeSelectorButton.addAction { [weak self] in
      self?.output?.didTapShapeSelector()
    }

    colorSelectorButton.addAction { [weak self] in
      self?.output?.didTapColorSelector()
    }
  }
}

extension BottomToolsGroup: SelectableIconsGroupDelegate {
  func didSelect(icon: SelectableIconsGroupModel.IconModel) {
    guard let tool = icon.model as? DrawingTool else { return }
    output?.didSelect(tool: tool)
  }
}

extension BottomToolsGroup: ColorSliderDelegate {
  func valueUpdate(color: UIColor, _ value: CGFloat) {
    output?.didSelectFPS(Int(value * 30))
  }
}

extension BottomToolsGroup: StateDependentView {
  func stateDidUpdate(newState: ProjectEditorState) {
    switch newState {
    case .readyForDrawing:
      drawingContainerView.alpha = 1
      fpsSlider.alpha = 0
    case .drawingInProgress:
      drawingContainerView.alpha = 0
      fpsSlider.alpha = 0
    case .managingFrames:
      drawingContainerView.alpha = 0
      fpsSlider.alpha = 0
    case .playing:
      drawingContainerView.alpha = 0
      fpsSlider.alpha = 1
    }
  }
}
