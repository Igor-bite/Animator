// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

final class LayersPreviewScrollView: UIView {
  private var layers = [LayerPreviewModel]()
  private lazy var collectionViewLayout = makeCollectionViewLayout()
  private lazy var collectionView = makeCollectionView()

  var itemAspectRatio: CGFloat = 2 {
    didSet {
      guard itemAspectRatio != oldValue else { return }
      collectionViewLayout.itemSize = CGSize(
        width: Constants.itemWidth,
        height: Constants.itemWidth * itemAspectRatio
      )
    }
  }

  init() {
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    CGSize(
      width: super.intrinsicContentSize.width,
      height: Constants.itemWidth * itemAspectRatio
    )
  }

  func configure(with layers: [LayerPreviewModel]) {
    self.layers = layers
    UIView.performWithoutAnimation {
      collectionView.reloadData()
      collectionView.scrollToItem(
        at: IndexPath(item: layers.count - 1, section: 0),
        at: .centeredHorizontally,
        animated: false
      )
    }
  }

  private func setupUI() {
    addSubviews(collectionView)

    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  private func makeCollectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.itemSize = CGSize(width: Constants.itemWidth, height: Constants.itemWidth * itemAspectRatio)
    layout.minimumInteritemSpacing = Constants.itemSpacing
    return layout
  }

  private func makeCollectionView() -> UICollectionView {
    let view = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    view.backgroundColor = .clear
    view.dataSource = self
    view.delegate = self
    view.showsHorizontalScrollIndicator = false
    view.showsVerticalScrollIndicator = false
    view.registerCell(of: LayerPreviewCell.self)
    return view
  }
}

extension LayersPreviewScrollView: UICollectionViewDelegate {
  func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {}
}

extension LayersPreviewScrollView: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    layers.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell: LayerPreviewCell? = collectionView.dequeueReusableCell(for: indexPath)
    if let model = layers[safe: indexPath.item] {
      cell?.configure(with: model)
    }
    return cell ?? UICollectionViewCell()
  }
}

extension LayersPreviewScrollView: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int
  ) -> UIEdgeInsets {
    let leftInset = (collectionView.frame.width - Constants.itemWidth) / 2
    let rightInset = leftInset

    return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
  }
}

extension LayersPreviewScrollView: StateDependentView {
  func stateDidUpdate(newState: ProjectEditorState) {
    switch newState {
    case .readyForDrawing:
      alpha = 0
    case .drawingInProgress:
      alpha = 0
    case let .managingFrames(frames):
      configure(with: frames.map { LayerPreviewModel(frame: $0) })
      alpha = 1
    case .playing:
      alpha = 0
    }
  }
}

private enum Constants {
  static let itemWidth = 32.0
  static let itemSpacing = 4.0
}
