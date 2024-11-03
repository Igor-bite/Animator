// Created by Igor Klyuzhev in 2024

import Combine
import IKDrawing
import IKUI
import UIKit

enum ProjectEditorState {
  /// Стейт готовый для рисования на холсте
  case readyForDrawing
  /// Стейт когда рисование в процессе
  case drawingInProgress
  /// Стейт просмотра фреймов
  case managingFrames
  /// Стейт проигрывания
  case playing
}

final class ProjectEditorViewModel: ProjectEditorViewOutput {
  private let coordinator: ProjectEditorCoordinating
  private var frames = [FrameModel]()
  private var currentFrameIndex = 0
  private lazy var imageRenderer: UIGraphicsImageRenderer = {
    let format = UIGraphicsImageRendererFormat()
    format.scale = UIScreen.main.scale
    format.preferredRange = .standard
    format.opaque = false
    return UIGraphicsImageRenderer(
      size: drawingAreaSize,
      format: format
    )
  }()

  weak var view: ProjectEditorViewInput?

  var state = CurrentValueSubject<ProjectEditorState, Never>(.readyForDrawing)
  var drawingConfig: DrawingViewConfiguration {
    didSet {
      updateDrawingViewConfig()
    }
  }

  var drawingInteractor: DrawingViewInteractor? {
    willSet {
      drawingInteractor?.delegate = nil
    }
    didSet {
      drawingInteractor?.delegate = self
    }
  }

  var drawingAreaSize: CGSize = .zero

  init(coordinator: ProjectEditorCoordinating) {
    self.coordinator = coordinator
    drawingConfig = DrawingViewConfiguration(
      tool: .pen,
      lineWidth: 20,
      color: Colors.Palette.blue
    )
  }

  private func updateDrawingViewConfig() {
    drawingInteractor?.didUpdateConfig(
      config: drawingConfig
    )
  }
}

extension ProjectEditorViewModel: TopToolsGroupOutput, BottomToolsGroupOutput {
  var canUndo: Bool {
    drawingInteractor?.canUndo ?? false
  }

  var canRedo: Bool {
    drawingInteractor?.canRedo ?? false
  }

  func undo() {
    drawingInteractor?.undo()
  }

  func redo() {
    drawingInteractor?.redo()
  }

  func removeLayer() {}

  func addNewLayer() {
    saveLayer(needsReset: true)
  }

  func duplicateLayer() {
    saveLayer(needsReset: false)
  }

  private func saveLayer(needsReset: Bool) {
    let frameImage = drawingInteractor?.produceCurrentSketchImage()
    frames.append(FrameModel(image: frameImage))
    currentFrameIndex += 1
    view?.updatePreviousFrame(with: frameImage)
    if needsReset {
      drawingInteractor?.resetForNewSketch()
    }
  }

  func openLayersView() {
    duplicateLayer()
  }

  func pause() {
    currentFrameIndex -= 1
    guard let frame = frames[safe: currentFrameIndex] else {
      currentFrameIndex = frames.count
      pause()
      return
    }
    view?.updatePreviousFrame(with: frame.image)
  }

  func play() {
    currentFrameIndex += 1
    guard let frame = frames[safe: currentFrameIndex] else {
      currentFrameIndex = -1
      play()
      return
    }
    view?.updatePreviousFrame(with: frame.image)
  }

  func didSelect(tool: DrawingTool) {
    if tool == drawingConfig.tool {
      drawingConfig.tool = nil
    } else {
      drawingConfig.tool = tool
    }
    view?.updateLineWidthAlpha()
  }

  func didTapShapeSelector() {}

  func didTapColorSelector() {
    view?.updateColorSelector(shouldClose: true)
  }
}

extension ProjectEditorViewModel: DrawingViewDelegate {
  func didUpdateCommandHistory() {
    view?.updateTopControls()
  }

  func didStartDrawing() {
    state.send(.drawingInProgress)
  }

  func didEndDrawing() {
    state.send(.readyForDrawing)
  }
}

extension ProjectEditorViewModel: LineWidthSelectorDelegate {
  func valueUpdate(_ value: CGFloat) {
    drawingConfig.lineWidth = 4 + 100 * value
    view?.updateLineWidthPreview()
    view?.updateLineWidthPreviewVisibility(isVisible: true)
  }

  func released() {
    view?.updateLineWidthPreviewVisibility(isVisible: false)
  }
}

extension ProjectEditorViewModel: ColorSelectorViewDelegate {
  func didSelect(color: UIColor, shouldClose: Bool) {
    drawingConfig.color = color
    view?.updateColorSelector(shouldClose: shouldClose)
  }
}
