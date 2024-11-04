// Created by Igor Klyuzhev in 2024

import Combine
import IKDrawing
import IKUI
import IKUtils
import SnapKit
import UIKit

protocol GeometrySelectorViewDelegate: AnyObject {
  func didSelect(object: GeometryObject)
}

final class GeometrySelectorView: UIView {
  private let blurView: UIView = {
    let blurView = UIVisualEffectView()
    blurView.isUserInteractionEnabled = false
    blurView.clipsToBounds = true
    blurView.effect = UIBlurEffect(style: .systemUltraThinMaterialLight)
    return blurView
  }()

  private lazy var iconsGroup: SelectableIconsGroup = {
    let icons: [SelectableIconsGroupModel.IconModel] = [
      .init(
        id: GeometryObject.square.rawValue,
        icon: Asset.square.image,
        model: GeometryObject.square
      ),
      .init(
        id: GeometryObject.circle.rawValue,
        icon: Asset.circle.image,
        model: GeometryObject.circle
      ),
      .init(
        id: GeometryObject.triangle.rawValue,
        icon: Asset.triangle.image,
        model: GeometryObject.triangle
      ),
      .init(
        id: GeometryObject.arrow.rawValue,
        icon: Asset.arrowUp.image,
        model: GeometryObject.arrow
      ),
    ]
    let model = SelectableIconsGroupModel(
      icons: icons,
      size: .medium(),
      intiallySelectedId: ""
    )
    let view = SelectableIconsGroup(model: model)
    view.delegate = self
    return view
  }()

  weak var delegate: GeometrySelectorViewDelegate?

  init() {
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func deselect() {
    iconsGroup.deselect()
  }

  private func setupUI() {
    blurView.smoothCornerRadius = 12

    addSubviews(
      blurView,
      iconsGroup
    )

    blurView.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      make.top.equalTo(iconsGroup.snp.top).offset(-16)
    }

    iconsGroup.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(16)
      make.trailing.bottom.equalToSuperview().offset(-16)
    }
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    guard alpha > 0 else { return false }
    if iconsGroup.frame.contains(point) {
      return true
    }
    return super.point(inside: point, with: event)
  }
}

extension GeometrySelectorView: SelectableIconsGroupDelegate {
  func didSelect(icon: SelectableIconsGroupModel.IconModel) {
    guard let object = icon.model as? GeometryObject else { return }
    delegate?.didSelect(object: object)
  }
}

extension GeometryObject {
  var image: UIImage {
    switch self {
    case .triangle:
      Asset.triangle.image
    case .circle:
      Asset.circle.image
    case .square:
      Asset.square.image
    case .arrow:
      Asset.arrowUp.image
    }
  }
}
