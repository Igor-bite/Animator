// Created by Igor Klyuzhev in 2024

import UIKit
import IKUtils
import IKUI
import SnapKit

protocol TopToolsGroupInput {}

protocol TopToolsGroupOutput: AnyObject {
  func undo()
  func redo()

  func removeLayer()
  func addNewLayer()
  func openLayersView()

  func pause()
  func play()
}

final class TopToolsGroup: UIView, TopToolsGroupInput {
  weak var output: TopToolsGroupOutput?

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
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    let redoUndoStack = UIStackView()
    redoUndoStack.spacing = 16
    redoUndoStack.addArrangedSubviews([
      undoButton,
      redoButton
    ])

    let layerToolsStack = UIStackView()
    layerToolsStack.spacing = 16
    layerToolsStack.addArrangedSubviews([
      removeLayerButton,
      addLayerButton,
      layersViewButton
    ])

    let playPauseStack = UIStackView()
    playPauseStack.spacing = 16
    playPauseStack.addArrangedSubviews([
      pauseButton,
      playButton
    ])

    let containerStack = UIStackView()
    containerStack.distribution = .equalSpacing
    containerStack.addArrangedSubviews([
      redoUndoStack,
      layerToolsStack,
      playPauseStack
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
}