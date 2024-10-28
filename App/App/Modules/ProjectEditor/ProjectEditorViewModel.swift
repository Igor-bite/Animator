// Created by Igor Klyuzhev in 2024

import Foundation
import Combine

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
