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

  func undo()
  func redo()

  func removeLayer()
  func addNewLayer()
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

  private let removeLayerButton = TapIcon(
    size: .large(),
    icon: Asset.bin.image
  )

  private let addLayerButton = TapIcon(
    size: .large(),
    icon: Asset.plusFile.image
  )

  private let layersViewButton = TapIcon(
    size: .large(),
    icon: Asset.layers.image
  )

  private let layerToolsStack = UIStackView()

  private let playPauseButton = TapIcon(
    size: .large(),
    icon: Asset.play.image,
    selectionType: .icon(Asset.pause.image)
  )

  private let shareButton = TapIcon(
    size: .large(),
    icon: UIImage(systemName: "square.and.arrow.up") ?? UIImage()
  )

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
      addLayerButton,
      layersViewButton,
    ])

    playPauseStack.spacing = 16
    playPauseStack.addArrangedSubviews([
      playPauseButton,
      shareButton,
    ])

    containerStack.distribution = .equalSpacing
    containerStack.addArrangedSubviews([
      redoUndoStack,
      layerToolsStack,
      playPauseStack,
    ])

    addSubview(containerStack)
    containerStack.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  private func setupActions() {
    undoButton.addAction { [weak self] in
      self?.output?.undo()
    }
    redoButton.addAction { [weak self] in
      self?.output?.redo()
    }
    removeLayerButton.addAction { [weak self] in
      self?.output?.removeLayer()
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
    case .drawingInProgress:
      redoUndoStack.alpha = 0
      layerToolsStack.alpha = 0
      playPauseStack.alpha = 0
    case .managingFrames:
      redoUndoStack.alpha = 0
      layerToolsStack.alpha = 0
      playPauseStack.alpha = 0
    case .playing:
      redoUndoStack.alpha = 0
      layerToolsStack.alpha = 0
      playPauseStack.alpha = 1
    }
  }
}
