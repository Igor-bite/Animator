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
    view.layer.borderColor = Colors.accent.cgColor
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

  func setSelection(isSelected: Bool) {
    UIView.animate(withDuration: 0.2) {
      self.containerView.transform = isSelected ? CGAffineTransform(scaleX: 1.15, y: 1.15) : .identity
      self.containerView.layer.borderWidth = isSelected ? 2 : 0
    }
  }

  override func prepareForReuse() {
    imageView.image = nil
    setSelection(isSelected: false)
  }

  private func setupUI() {
    clipsToBounds = false
    containerView.clipsToBounds = false
    contentView.clipsToBounds = false
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
