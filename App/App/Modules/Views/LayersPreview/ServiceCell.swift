// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

final class LayerActionCell: UICollectionViewCell {
  enum ActionType {
    case createNewLayer
    case generateLayers

    var image: UIImage {
      switch self {
      case .createNewLayer:
        Asset.plusFile.image
      case .generateLayers:
        Asset.instruments.image
      }
    }
  }

  private let imageView = {
    let view = UIImageView()
    view.tintColor = Colors.Palette.black
    view.contentMode = .scaleAspectFit
    return view
  }()

  private let containerView = {
    let view = ScalableView()
    view.backgroundColor = Colors.accent
    view.smoothCornerRadius = 4
    view.isUserInteractionEnabled = true
    return view
  }()

  private var action: ActionType?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with action: ActionType) {
    imageView.image = action.image.withRenderingMode(.alwaysTemplate)
  }

  private func setupUI() {
    contentView.addSubview(containerView)
    containerView.addSubview(imageView)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    imageView.snp.makeConstraints { make in
      make.centerX.centerY.equalToSuperview()
      make.height.width.equalTo(24)
    }
  }
}
