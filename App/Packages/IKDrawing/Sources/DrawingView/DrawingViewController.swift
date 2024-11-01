// Created by Igor Klyuzhev in 2024

import Foundation

public protocol DrawingViewInteractor {
  var canUndo: Bool { get }
  var canRedo: Bool { get }

  func undo()
  func redo()
  func didUpdateConfig(config: DrawingViewConfiguration)
}

final class DrawingViewController: DrawingViewOutput {
  weak var view: DrawingViewInput?

  var config: DrawingViewConfiguration

  private var history = [DrawingCommand]()
  private var redoHistory = [DrawingCommand]()

  init(config: DrawingViewConfiguration) {
    self.config = config
  }

  func commit(command: DrawingCommand) {
    history.append(command)
  }

  func clearRedoHistory() {
    redoHistory.removeAll()
  }
}

extension DrawingViewController: DrawingViewInteractor {
  var canUndo: Bool {
    !history.isEmpty
  }

  var canRedo: Bool {
    !redoHistory.isEmpty
  }

  func undo() {
    guard canUndo else { return }
    let lastCommand = history.removeLast()
    redoHistory.append(lastCommand)
    view?.execute(command: lastCommand.inverted)
  }

  func redo() {
    guard canRedo else { return }
    let lastCommand = redoHistory.removeLast()
    history.append(lastCommand)
    view?.execute(command: lastCommand)
  }

  func didUpdateConfig(config: DrawingViewConfiguration) {
    self.config = config
  }
}
