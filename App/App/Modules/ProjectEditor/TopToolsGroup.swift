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

  private let pauseButton = TapIcon(
    size: .large(),
    icon: Asset.pause.image
  )

  private let playButton = TapIcon(
    size: .large(),
    icon: Asset.play.image
  )

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
    let redoUndoStack = UIStackView()
    redoUndoStack.spacing = 16
    redoUndoStack.addArrangedSubviews([
      undoButton,
      redoButton,
    ])

    let layerToolsStack = UIStackView()
    layerToolsStack.spacing = 16
    layerToolsStack.addArrangedSubviews([
      removeLayerButton,
      addLayerButton,
      layersViewButton,
    ])

    let playPauseStack = UIStackView()
    playPauseStack.spacing = 16
    playPauseStack.addArrangedSubviews([
      pauseButton,
      playButton,
    ])

    let containerStack = UIStackView()
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
    pauseButton.addAction { [weak self] in
      self?.output?.pause()
    }
    playButton.addAction { [weak self] in
      self?.output?.play()
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
