// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

protocol LayersPreviewDelegate: AnyObject {
  func didSelectFrame(at index: Int)
  func addNewFrameToEnd()
  func triggerGenerateFramesFlow()
}

final class LayersPreviewScrollView: UIView {
  private var layers = [LayerPreviewModel]()
  private lazy var collectionViewLayout = makeCollectionViewLayout()
  private lazy var collectionView = makeCollectionView()
  private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
  private var needsScrollSelection = true
  private var selectionIndex: Int?
  private var selectedCell: LayerPreviewCell?

  private var serviceActions: [LayerActionCell.ActionType] = [
    .createNewLayer,
    .generateLayers,
  ]

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
    selectionIndex: Int,
    animated: Bool
  ) {
    impactGenerator.prepare()
    self.layers = layers
    self.selectionIndex = selectionIndex
    if !animated {
      UIView.performWithoutAnimation {
        collectionView.reloadData()
        collectionView.scrollToItem(
          at: IndexPath(item: selectionIndex, section: .zero),
          at: .centeredHorizontally,
          animated: false
        )
      }
    } else {
      collectionView.reloadData()
      collectionView.scrollToItem(
        at: IndexPath(item: selectionIndex, section: .zero),
        at: .centeredHorizontally,
        animated: true
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
    view.registerCell(of: LayerActionCell.self)
    return view
  }
}

extension LayersPreviewScrollView: UICollectionViewDelegate {
  func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    handleCellSelection(at: indexPath)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didDeselectItemAt indexPath: IndexPath
  ) {
    handleCellSelection(at: indexPath)
  }

  private func handleCellSelection(at indexPath: IndexPath) {
    if indexPath.item < layers.count {
      needsScrollSelection = false
      delegate?.didSelectFrame(at: indexPath.item)

      self.selectedCell?.setSelection(isSelected: false)
      let selectedCell = collectionView.cellForItem(at: indexPath)
      self.selectedCell = selectedCell as? LayerPreviewCell
      self.selectedCell?.setSelection(isSelected: true)
      collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    } else {
      let actionIndex = indexPath.item - layers.count
      let action = serviceActions[actionIndex]
      handleServiceAction(action)
    }
    impactGenerator.impactOccurred()
  }

  private func handleServiceAction(_ action: LayerActionCell.ActionType) {
    switch action {
    case .createNewLayer:
      delegate?.addNewFrameToEnd()
    case .generateLayers:
      delegate?.triggerGenerateFramesFlow()
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard needsScrollSelection,
          let indexPath = collectionView.indexPathForItem(
            at: collectionView.bounds.center
          ),
          indexPath.item < layers.count,
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
    let item = Int((cur + Constants.itemWidth / 2) / itemSize)
    if item < layers.count {
      let new = Double(item - 1) * itemSize + Constants.itemWidth
      targetContentOffset.pointee.x = max(0, new)
    } else {
      let new = Double(layers.count - 2) * itemSize + Constants.itemWidth
      targetContentOffset.pointee.x = max(0, new)
    }
  }
}

extension LayersPreviewScrollView: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    layers.count + serviceActions.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    if indexPath.item >= layers.count {
      let cell: LayerActionCell? = collectionView.dequeueReusableCell(for: indexPath)
      let actionIndex = indexPath.item - layers.count
      let action = serviceActions[actionIndex]
      cell?.configure(with: action)
      return cell ?? UICollectionViewCell()
    } else {
      let cell: LayerPreviewCell? = collectionView.dequeueReusableCell(for: indexPath)
      if let model = layers[safe: indexPath.item] {
        cell?.configure(with: model)
      }
      if let selectionIndex,
         indexPath.item == selectionIndex
      {
        self.selectionIndex = nil
        cell?.setSelection(isSelected: true)
      } else {
        cell?.setSelection(isSelected: false)
      }
      return cell ?? UICollectionViewCell()
    }
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
      if alpha == 0 {
        alpha = 1
        configure(
          with: frames.map { LayerPreviewModel(frame: $0) },
          selectionIndex: selectionIndex,
          animated: false
        )
      } else {
        configure(
          with: frames.map { LayerPreviewModel(frame: $0) },
          selectionIndex: selectionIndex,
          animated: false
        )
      }
    case .generationFlow:
      break
    case .playing:
      alpha = 0
    }
  }
}

private enum Constants {
  static let itemWidth = 32.0
  static let itemSpacing = 6.0
}
