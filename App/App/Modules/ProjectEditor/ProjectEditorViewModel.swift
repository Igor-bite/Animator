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
  case managingFrames(frames: [FrameModel], selectionIndex: Int)
  /// Стейт проигрывания
  case playing

  var needsAnimatedChange: Bool {
    true
  }
}

final class ProjectEditorViewModel: ProjectEditorViewOutput {
  private let coordinator: ProjectEditorCoordinating
  private let gifExporter = GIFExporter()
  private var frames = [FrameModel(image: nil, previewSize: .zero)] {
    didSet {
      view?.updateTopControls()
    }
  }

  private var selectedFrameIndex = 0
  private var framePreviewSize: CGSize {
    CGSize(
      width: 32,
      height: 32 * drawingAreaSize.height / drawingAreaSize.width
    )
  }

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

  var playerConfig: FramesPlayerConfig {
    didSet {
      updatePlayerViewConfig()
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

  var playerInteractor: FramesPlayerInteractor?

  var drawingAreaSize: CGSize = .zero

  init(coordinator: ProjectEditorCoordinating) {
    self.coordinator = coordinator
    drawingConfig = DrawingViewConfiguration(
      tool: .pen,
      lineWidth: 20,
      color: Colors.Palette.blue
    )
    playerConfig = FramesPlayerConfig(fps: 10)
  }

  private func updateDrawingViewConfig() {
    drawingInteractor?.didUpdateConfig(
      config: drawingConfig
    )
  }

  private func updatePlayerViewConfig() {
    playerInteractor?.didUpdateConfig(playerConfig)
  }
}

extension ProjectEditorViewModel: TopToolsGroupOutput, BottomToolsGroupOutput {
  var canUndo: Bool {
    drawingInteractor?.canUndo ?? false
  }

  var canRedo: Bool {
    drawingInteractor?.canRedo ?? false
  }

  var canPlay: Bool {
    frames.count > 1
  }

  var canOpenLayers: Bool {
    true
  }

  func undo() {
    drawingInteractor?.undo()
  }

  func redo() {
    drawingInteractor?.redo()
  }

  func removeLayer() {
    if frames.count == 1 {
      drawingInteractor?.resetForNewSketch()
      frames[0] = FrameModel(image: nil, previewSize: .zero)
    } else {
      frames.remove(at: selectedFrameIndex)
      let newSelectionIndex = max(selectedFrameIndex - 1, 0)
      didSelectFrame(at: newSelectionIndex)
    }
    updateLayersViewIfNeeded()
  }

  func duplicateLayer() {
    let frameImage = drawingInteractor?.produceCurrentSketchImage()
    frames[selectedFrameIndex] = FrameModel(
      image: frameImage,
      previewSize: framePreviewSize
    )
    selectedFrameIndex += 1
    frames.insert(
      FrameModel(
        image: frameImage,
        previewSize: framePreviewSize
      ),
      at: selectedFrameIndex
    )
    view?.updatePreviousFrame(with: frameImage)
    updateLayersViewIfNeeded()
  }

  func addNewLayer() {
    addNewLayer(at: selectedFrameIndex, needsSelection: true)
  }

  private func addNewLayer(at index: Int, needsSelection: Bool) {
    if needsSelection {
      let frameImage = drawingInteractor?.produceCurrentSketchImage()
      frames[selectedFrameIndex] = FrameModel(
        image: frameImage,
        previewSize: framePreviewSize
      )
      view?.updatePreviousFrame(with: frameImage)
      selectedFrameIndex = index
      drawingInteractor?.resetForNewSketch()
    }
    frames.insert(
      FrameModel(
        image: nil,
        previewSize: framePreviewSize
      ),
      at: index
    )
    updateLayersViewIfNeeded()
  }

  private func updateLayersViewIfNeeded() {
    guard case .managingFrames = state.value else { return }
    state.send(.managingFrames(frames: frames, selectionIndex: selectedFrameIndex))
  }

  private func syncCurrentFrameImage() {
    let frameImage = drawingInteractor?.produceCurrentSketchImage()
    frames[selectedFrameIndex] = FrameModel(
      image: frameImage,
      previewSize: framePreviewSize
    )
  }

  func openLayersView() {
    guard frames.count > 0 else { return }
    if case .managingFrames = state.value {
      let previousFrameImage = frames[safe: selectedFrameIndex - 1]?.image
      view?.updatePreviousFrame(with: previousFrameImage)
      if let currentFrameImage = frames[safe: selectedFrameIndex]?.image {
        drawingInteractor?.set(frame: currentFrameImage)
      } else {
        drawingInteractor?.resetForNewSketch()
      }
      state.send(.readyForDrawing)
    } else {
      syncCurrentFrameImage()
      state.send(.managingFrames(frames: frames, selectionIndex: selectedFrameIndex))
    }
  }

  func share() {
    gifExporter.export(
      frames: frames,
      fps: playerConfig.fps
    )
  }

  func pause() {
    state.send(.readyForDrawing)
    playerInteractor?.configure(with: [])
    playerInteractor?.stop()
  }

  func play() {
    guard canPlay else { return }
    syncCurrentFrameImage()
    state.send(.playing)
    playerInteractor?.configure(with: frames)
    playerInteractor?.start()
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

  func didSelectFPS(_ newValue: Int) {
    playerConfig.fps = max(1, min(30, newValue))
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

extension ProjectEditorViewModel: LayersPreviewDelegate {
  func didSelectFrame(at index: Int) {
    guard let frame = frames[safe: index] else { return }
    selectedFrameIndex = index
    if let frameImage = frame.image {
      drawingInteractor?.set(frame: frameImage)
    } else {
      drawingInteractor?.resetForNewSketch()
    }
    view?.updatePreviousFrame(with: frames[safe: index - 1]?.image)

    frames[safe: index - 2]?.prefetchImage()
    frames[safe: index + 1]?.prefetchImage()
  }

  func addNewFrameToEnd() {
    addNewLayer(at: frames.count, needsSelection: true)
  }

  func triggerGenerateFramesFlow() {}
}
