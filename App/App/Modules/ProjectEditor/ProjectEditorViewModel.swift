// Created by Igor Klyuzhev in 2024

import Combine
import Foundation

enum ProjectEditorState {
  /// Стейт рисования на холсте
  case drawing
  /// Стейт просмотра фреймов
  case managingFrames
  /// Стейт проигрывания
  case playing
}

final class ProjectEditorViewModel: ProjectEditorViewOutput {
  private let coordinator: ProjectEditorCoordinating

  weak var view: ProjectEditorViewInput?

  var state = CurrentValueSubject<ProjectEditorState, Never>(.drawing)

  init(coordinator: ProjectEditorCoordinating) {
    self.coordinator = coordinator
  }
}

extension ProjectEditorViewModel: TopToolsGroupOutput, BottomToolsGroupOutput {
  func undo() {}

  func redo() {}

  func removeLayer() {}

  func addNewLayer() {}

  func openLayersView() {}

  func pause() {}

  func play() {}

  func didSelect(tool: ToolType) {}

  func didTapShapeSelector() {}

  func didTapColorSelector() {}
}
