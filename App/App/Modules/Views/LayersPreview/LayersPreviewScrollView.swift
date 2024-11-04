// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

protocol LayersPreviewDelegate: AnyObject {
  func didSelectFrame(at index: Int)
}

final class LayersPreviewScrollView: UIView {
  private var layers = [LayerPreviewModel]()
  private lazy var collectionViewLayout = makeCollectionViewLayout()
  private lazy var collectionView = makeCollectionView()
  private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
  private var needsScrollSelection = true
  private var selectionIndex: Int?

  var itemAspectRatio: CGFloat = 2 {
    didSet {
      guard itemAspectRatio != oldValue else { return }
      collectionViewLayout.itemSize = CGSize(
        width: Constants.itemWidth,
        height: Constants.itemWidth * itemAspectRatio
      )
    }
  }

  override var intrinsicContentSize: CGSize {
    CGSize(
      width: super.intrinsicContentSize.width,
      height: Constants.itemWidth * itemAspectRatio
    )
  }

  weak var delegate: LayersPreviewDelegate?

  init() {
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(
    with layers: [LayerPreviewModel],
    selectionIndex: Int
  ) {
    impactGenerator.prepare()
    self.layers = layers
    self.selectionIndex = selectionIndex
    UIView.performWithoutAnimation {
      collectionView.reloadData()
      collectionView.scrollToItem(
        at: IndexPath(item: selectionIndex, section: .zero),
        at: .centeredHorizontally,
        animated: false
      )
    }
    delegate?.didSelectFrame(at: selectionIndex)
  }

  private func setupUI() {
    clipsToBounds = false
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
    layout.minimumLineSpacing = Constants.itemSpacing
    return layout
  }

  private func makeCollectionView() -> UICollectionView {
    let view = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    view.backgroundColor = .clear
    view.dataSource = self
    view.delegate = self
    view.showsHorizontalScrollIndicator = false
    view.showsVerticalScrollIndicator = false
    view.allowsSelection = true
    view.allowsMultipleSelection = true
    view.isPagingEnabled = false
    view.delaysContentTouches = false
    view.registerCell(of: LayerPreviewCell.self)
    return view
  }

  private var selectedCell: LayerPreviewCell?
}

extension LayersPreviewScrollView: UICollectionViewDelegate {
  func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    needsScrollSelection = false
    delegate?.didSelectFrame(at: indexPath.item)

    self.selectedCell?.setSelection(isSelected: false)
    let selectedCell = collectionView.cellForItem(at: indexPath)
    self.selectedCell = selectedCell as? LayerPreviewCell
    self.selectedCell?.setSelection(isSelected: true)
    collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    impactGenerator.impactOccurred()
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard needsScrollSelection,
          let indexPath = collectionView.indexPathForItem(
            at: collectionView.bounds.center
          ),
          let selectedCell = collectionView.cellForItem(at: indexPath),
          selectedCell != self.selectedCell
    else { return }

    delegate?.didSelectFrame(at: indexPath.item)
    self.selectedCell?.setSelection(isSelected: false)
    self.selectedCell = selectedCell as? LayerPreviewCell
    self.selectedCell?.setSelection(isSelected: true)

    impactGenerator.impactOccurred()
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    needsScrollSelection = true
  }

  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    needsScrollSelection = true
  }

  func scrollViewWillEndDragging(
    _ scrollView: UIScrollView,
    withVelocity velocity: CGPoint,
    targetContentOffset: UnsafeMutablePointer<CGPoint>
  ) {
    let cur = targetContentOffset.pointee.x - scrollView.contentInset.left
    let itemSize = Constants.itemWidth + Constants.itemSpacing
    let item = ((cur + Constants.itemWidth / 2) / itemSize).rounded(.down)
    let new = (item - 1) * itemSize + Constants.itemWidth

    targetContentOffset.pointee.x = max(0, new)
  }
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
    if let selectionIndex,
       indexPath.item == selectionIndex
    {
      self.selectionIndex = nil
      cell?.setSelection(isSelected: true)
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
    case let .managingFrames(frames, selectionIndex):
      configure(with: frames.map { LayerPreviewModel(frame: $0) }, selectionIndex: selectionIndex)
      alpha = 1
    case .playing:
      alpha = 0
    }
  }
}

private enum Constants {
  static let itemWidth = 32.0
  static let itemSpacing = 6.0
}
