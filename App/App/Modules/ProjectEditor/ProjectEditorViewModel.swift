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
  /// Стейт генерации фреймов
  case generationFlow(state: GenerationFlowState)

  var needsAnimatedChange: Bool {
    if case .generationFlow = self {
      return false
    }
    return true
  }

  enum GenerationFlowState {
    case settings
    case loading
  }
}

final class ProjectEditorViewModel: ProjectEditorViewOutput {
  private let coordinator: ProjectEditorCoordinating
  private lazy var gifExporter = GIFExporter(imageSize: drawingAreaSize)
  private let framesGenerator = FramesGenerator()
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

  private var stateBeforeGeneration: ProjectEditorState?

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

  func removeAll() {
    view?.askToRemoveAll { [weak self] in
      guard let self else { return }
      frames.removeAll()
      frames.append(FrameModel(image: nil, previewSize: framePreviewSize))
      selectedFrameIndex = 0
      drawingInteractor?.resetForNewSketch()
      view?.updatePreviousFrame(with: nil)
      state.send(.readyForDrawing)
    }
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
    addNewLayer(at: selectedFrameIndex + 1, needsSelection: true)
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

  private func updateLayersViewIfNeeded(force: Bool = false) {
    let action = {
      self.state.send(
        .managingFrames(
          frames: self.frames,
          selectionIndex: self.selectedFrameIndex
        )
      )
    }
    if force {
      action()
    } else if case .managingFrames = state.value {
      action()
    }
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
    playerInteractor?.stop()
    view?.showExportLoadingAlert()
    gifExporter.export(
      frames: frames,
      fps: playerConfig.fps
    ) { [weak self] in
      self?.view?.closeExportLoadingAlert()
    } quickLookDismissed: { [weak self] in
      if case .playing = self?.state.value {
        self?.playerInteractor?.start()
      }
    }
  }

  func cancelExport() {
    gifExporter.isCancelled = true
    if case .playing = state.value {
      playerInteractor?.start()
    }
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

  func didTapShapeSelector() {
    view?.updateGeometrySelector()
  }

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

  func triggerGenerateFramesFlow() {
    stateBeforeGeneration = state.value
    state.send(.generationFlow(state: .settings))
  }

  func cancelGenerationFlow() {
    framesGenerator.cancel()
    if let stateBeforeGeneration {
      state.send(stateBeforeGeneration)
      self.stateBeforeGeneration = nil
    } else {
      state.send(.readyForDrawing)
    }
  }

  func generateFrames(count: Int) {
    state.send(.generationFlow(state: .loading))
    framesGenerator.config = drawingConfig
    framesGenerator.drawingRect = CGRect(origin: .zero, size: drawingAreaSize)
    framesGenerator.previewSize = framePreviewSize

    framesGenerator.generateFrames(count: count) { [weak self] generatedFrames in
      guard let self,
            case .generationFlow = state.value
      else { return }

      frames.append(contentsOf: generatedFrames)
      selectedFrameIndex = frames.count - 1
      updateLayersViewIfNeeded(force: true)
    }
  }
}

extension ProjectEditorViewModel: GeometrySelectorViewDelegate {
  func didSelect(object: GeometryObject) {
    if drawingConfig.selectedShape == object {
      drawingConfig.tool = nil
    } else {
      drawingConfig.tool = .geometry(object)
    }
    view?.updateGeometrySelector()
    view?.updateLineWidthAlpha()
  }
}
