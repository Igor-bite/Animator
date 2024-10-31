// Created by Igor Klyuzhev in 2024

import IKUtils
import SnapKit
import UIKit

public struct SelectableIconsGroupModel {
  public struct IconModel {
    public let id: String
    public let icon: UIImage

    public init(id: String, icon: UIImage) {
      self.id = id
      self.icon = icon
    }
  }

  public let icons: [IconModel]
  public let tint: UIColor
  public let selectedTint: UIColor
  public let size: TapIcon.SizeType
  public let spacing: CGFloat
  public let intiallySelectedId: String

  public init(
    icons: [IconModel],
    tint: UIColor = Colors.foreground,
    selectedTint: UIColor = Colors.accent,
    size: TapIcon.SizeType = .large(),
    spacing: CGFloat = .inset16,
    intiallySelectedId: String
  ) {
    self.icons = icons
    self.tint = tint
    self.selectedTint = selectedTint
    self.size = size
    self.spacing = spacing
    self.intiallySelectedId = intiallySelectedId
  }
}

public protocol SelectableIconsGroupDelegate: AnyObject {
  func didSelect(icon: SelectableIconsGroupModel.IconModel)
}

public final class SelectableIconsGroup: UIView {
  private let model: SelectableIconsGroupModel
  private var selectedView: TapIcon?
  private var iconViews = [TapIcon]()

  public weak var delegate: SelectableIconsGroupDelegate?

  override public var intrinsicContentSize: CGSize {
    let iconsSize = TapIcon.Size(type: model.size)
    let width = iconsSize.iconSize * CGFloat(model.icons.count) + model.spacing * CGFloat(model.icons.count - 1)
    let height = iconsSize.iconSize
    return CGSize(width: width, height: height)
  }

  public init(model: SelectableIconsGroupModel) {
    self.model = model
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupUI() {
    let elementsStack = UIStackView()
    elementsStack.spacing = model.spacing
    addSubview(elementsStack)

    elementsStack.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    iconViews = model.icons.map { icon in
      let view = makeView(for: icon)
      elementsStack.addArrangedSubview(view)
      return view
    }
  }

  private func makeView(for iconModel: SelectableIconsGroupModel.IconModel) -> TapIcon {
    let icon = TapIcon(
      size: model.size,
      icon: iconModel.icon,
      tint: model.tint,
      selectionType: .tint(Colors.accent)
    )
    if iconModel.id == model.intiallySelectedId {
      icon.isSelected = true
      selectedView = icon
    }
    icon.addAction { [weak self] in
      guard let self else { return }
      if selectedView == icon {
        selectedView = nil
      }
      selectedView?.isSelected = false
      selectedView = icon
      delegate?.didSelect(icon: iconModel)
    }
    return icon
  }
}
