// Created by Igor Klyuzhev in 2024

import Combine
import IKUI
import IKUtils
import SnapKit
import UIKit

protocol TopToolsGroupInput {
  func updateUI()
}

protocol TopToolsGroupOutput: AnyObject {
  var canUndo: Bool { get }
  var canRedo: Bool { get }
  var canPlay: Bool { get }
  var canOpenLayers: Bool { get }

  func undo()
  func redo()

  func removeAll()
  func removeLayer()
  func addNewLayer()
  func duplicateLayer()
  func openLayersView()

  func share()

  func pause()
  func play()
}

final class TopToolsGroup: UIView {
  weak var output: TopToolsGroupOutput? {
    didSet {
      updateButtons()
    }
  }

  private let undoButton = TapIcon(
    size: .medium(),
    icon: Asset.back.image
  )

  private let redoButton = TapIcon(
    size: .medium(),
    icon: Asset.forward.image
  )

  private let redoUndoStack = UIStackView()

  private let removeAllLayersButton = {
    let view = TapIcon(
      size: .large(),
      icon: Asset.bin.image
    )
    view.alpha = 0
    return view
  }()

  private let removeLayerButton = TapIcon(
    size: .large(),
    icon: Asset.removeDoc.image
  )

  private let duplicateLayerButton = TapIcon(
    size: .large(),
    icon: Asset.duplicate.image
  )

  private let addLayerButton = TapIcon(
    size: .large(),
    icon: Asset.plusFile.image
  )

  private let layersViewButton = TapIcon(
    size: .large(),
    icon: Asset.layers.image,
    selectionType: .tint(Colors.accent)
  )

  private let layerToolsStack = UIStackView()

  private let playPauseButton = TapIcon(
    size: .large(),
    icon: Asset.play.image,
    selectionType: .icon(Asset.pause.image)
  )

  private let shareButton = {
    let view = TapIcon(
      size: .large(),
      icon: Asset.share.image
    )
    view.alpha = 0
    return view
  }()

  private let playPauseStack = UIStackView()
  private let containerStack = UIStackView()

  init() {
    super.init(frame: .zero)
    setupUI()
    setupActions()
    updateButtons()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    redoUndoStack.spacing = 16
    redoUndoStack.addArrangedSubviews([
      undoButton,
      redoButton,
    ])

    layerToolsStack.spacing = 16
    layerToolsStack.addArrangedSubviews([
      removeLayerButton,
      duplicateLayerButton,
      addLayerButton,
      layersViewButton,
    ])

    playPauseStack.spacing = 16
    playPauseStack.addArrangedSubviews([
      shareButton,
      playPauseButton,
    ])

    containerStack.distribution = .equalSpacing
    containerStack.addArrangedSubviews([
      redoUndoStack,
      layerToolsStack,
      playPauseStack,
    ])

    addSubviews(containerStack, removeAllLayersButton)
    containerStack.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    removeAllLayersButton.snp.makeConstraints { make in
      make.top.leading.equalToSuperview()
    }
  }

  private func setupActions() {
    undoButton.addAction { [weak self] in
      self?.output?.undo()
    }
    redoButton.addAction { [weak self] in
      self?.output?.redo()
    }
    removeAllLayersButton.addAction { [weak self] in
      self?.output?.removeAll()
    }
    removeLayerButton.addAction { [weak self] in
      self?.output?.removeLayer()
    }
    duplicateLayerButton.addAction { [weak self] in
      self?.output?.duplicateLayer()
    }
    addLayerButton.addAction { [weak self] in
      self?.output?.addNewLayer()
    }
    layersViewButton.addAction { [weak self] in
      self?.output?.openLayersView()
    }
    playPauseButton.addAction { [weak self] in
      if self?.playPauseButton.isSelected == true {
        self?.output?.play()
      } else {
        self?.output?.pause()
      }
    }
    shareButton.addAction { [weak self] in
      self?.output?.share()
    }
  }

  private func updateButtons() {
    guard let output else { return }

    let undoTint = output.canUndo ? Colors.foreground : Colors.disabled
    undoButton.configure(
      tint: undoTint,
      selectionType: .tint(undoTint)
    )
    undoButton.isUserInteractionEnabled = output.canUndo

    let redoTint = output.canRedo ? Colors.foreground : Colors.disabled
    redoButton.configure(
      tint: redoTint,
      selectionType: .tint(redoTint)
    )
    redoButton.isUserInteractionEnabled = output.canRedo

    let playTint = output.canPlay ? Colors.foreground : Colors.disabled
    playPauseButton.configure(
      tint: playTint,
      selectionType: .icon(Asset.pause.image)
    )
    playPauseButton.isUserInteractionEnabled = output.canPlay
  }
}

extension TopToolsGroup: TopToolsGroupInput {
  func updateUI() {
    updateButtons()
  }
}

extension TopToolsGroup: StateDependentView {
  func stateDidUpdate(newState: ProjectEditorState) {
    switch newState {
    case .readyForDrawing:
      redoUndoStack.alpha = 1
      layerToolsStack.alpha = 1
      playPauseStack.alpha = 1
      removeAllLayersButton.alpha = 0
      layersViewButton.isSelected = false
      shareButton.alpha = 0
    case .drawingInProgress:
      redoUndoStack.alpha = 0
      layerToolsStack.alpha = 0
      playPauseStack.alpha = 0
      removeAllLayersButton.alpha = 0
      layersViewButton.isSelected = false
      shareButton.alpha = 0
    case .managingFrames:
      redoUndoStack.alpha = 0
      layerToolsStack.alpha = 1
      playPauseStack.alpha = 0
      removeAllLayersButton.alpha = 1
      layersViewButton.isSelected = true
      shareButton.alpha = 0
    case .playing:
      redoUndoStack.alpha = 0
      layerToolsStack.alpha = 0
      playPauseStack.alpha = 1
      removeAllLayersButton.alpha = 0
      shareButton.alpha = 1
    case .generationFlow:
      break
    }
  }
}
