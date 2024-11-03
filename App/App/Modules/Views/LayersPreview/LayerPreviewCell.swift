// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

final class LayerPreviewCell: UICollectionViewCell {
  private let imageView = {
    let view = UIImageView()
    return view
  }()

  private let containerView = {
    let view = UIView()
    view.backgroundColor = Colors.foreground
    view.smoothCornerRadius = 4
    return view
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with model: LayerPreviewModel) {
    imageView.image = model.previewImage
  }

  override func prepareForReuse() {
    imageView.image = nil
  }

  private func setupUI() {
    contentView.addSubview(containerView)
    containerView.addSubview(imageView)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    imageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
}
