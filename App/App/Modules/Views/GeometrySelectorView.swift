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
    blurView.backgroundColor = Colors.background.withAlphaComponent(0.3)
    return blurView
  }()

  private lazy var iconsGroup: SelectableIconsGroup = {
    let icons: [SelectableIconsGroupModel.IconModel] = GeometryObject.allCases.map { object in
      .init(
        id: object.rawValue,
        icon: object.image,
        model: object
      )
    }
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
    if blurView.frame.contains(point) {
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
      return Asset.triangle.image
    case .circle:
      return Asset.circle.image
    case .square:
      return Asset.square.image
    case .arrow:
      return Asset.arrowUp.image
    case .line:
      let format = UIGraphicsImageRendererFormat()
      format.opaque = false
      format.preferredRange = .standard
      format.scale = 1
      return UIGraphicsImageRenderer(size: .size32, format: format).image { ctx in
        let ctx = ctx.cgContext
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setLineWidth(2)
        ctx.move(to: CGPoint(x: 4, y: 28))
        ctx.addLine(to: CGPoint(x: 28, y: 4))
        ctx.strokePath()
      }
    }
  }
}
