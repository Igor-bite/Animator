// Created by Igor Klyuzhev in 2024

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
}

struct BottomToolsGroupModel {
  let selectedTool: DrawingTool?
  let selectedColor: UIColor
}

final class BottomToolsGroup: UIView, BottomToolsGroupInput {
  weak var output: BottomToolsGroupOutput?

  private lazy var drawingToolsButtons: SelectableIconsGroup = {
    let icons: [SelectableIconsGroupModel.IconModel] = [
      .init(id: DrawingTool.pen.rawValue, icon: Asset.pencil.image),
//      .init(id: "brush", icon: Asset.brush.image),
      .init(id: DrawingTool.eraser.rawValue, icon: Asset.eraser.image),
    ]
    let model = SelectableIconsGroupModel(
      icons: icons,
      intiallySelectedId: model.selectedTool?.rawValue ?? ""
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

  private let model: BottomToolsGroupModel

  init(model: BottomToolsGroupModel) {
    self.model = model
    super.init(frame: .zero)
    setupUI()
    setupActions()
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

  private func setupUI() {
    let spacing = 16
    let containerView = UIView()
    containerView.addSubviews(
      drawingToolsButtons,
      shapeSelectorButton,
      colorSelectorButton
    )

    addSubview(containerView)
    containerView.snp.makeConstraints { make in
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
    guard let tool = DrawingTool(rawValue: icon.id) else { return }
    output?.didSelect(tool: tool)
  }
}
