// Created by Igor Klyuzhev in 2024

import UIKit
import IKUtils
import IKUI
import SnapKit

protocol BottomToolsGroupInput {}

protocol BottomToolsGroupOutput: AnyObject {
  func didSelect(tool: ToolType)
  func didTapShapeSelector()
  func didTapColorSelector()
}

struct BottomToolsGroupModel {
  let selectedTool: ToolType
  let selectedColor: UIColor
}

final class BottomToolsGroup: UIView, BottomToolsGroupInput {
  weak var output: BottomToolsGroupOutput?

  private lazy var drawingToolsButtons: SelectableIconsGroup = {
    let icons: [SelectableIconsGroupModel.IconModel] = [
      .init(id: ToolType.pencil.rawValue, icon: Asset.pencil.image),
      .init(id: ToolType.brush.rawValue, icon: Asset.brush.image),
      .init(id: ToolType.eraser.rawValue, icon: Asset.eraser.image)
    ]
    let model = SelectableIconsGroupModel(
      icons: icons,
      intiallySelectedId: ToolType.pencil.rawValue
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

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
    guard let tool = ToolType(rawValue: icon.id) else { return }
    output?.didSelect(tool: tool)
  }
}