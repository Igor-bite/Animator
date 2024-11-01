// Created by Igor Klyuzhev in 2024

import Foundation

public protocol DrawingViewInteractor {
  var delegate: DrawingViewDelegate? { get set }
  var canUndo: Bool { get }
  var canRedo: Bool { get }

  func undo()
  func redo()
  func didUpdateConfig(config: DrawingViewConfiguration)
}

final class DrawingViewController: DrawingViewOutput {
  weak var view: DrawingViewInput?
  weak var delegate: DrawingViewDelegate?

  var config: DrawingViewConfiguration

  private var history = [DrawingCommand]()
  private var redoHistory = [DrawingCommand]()

  init(config: DrawingViewConfiguration) {
    self.config = config
  }

  func commit(command: DrawingCommand) {
    history.append(command)
    delegate?.didUpdateCommandHistory()
  }

  func clearRedoHistory() {
    redoHistory.removeAll()
    delegate?.didUpdateCommandHistory()
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
    delegate?.didUpdateCommandHistory()
  }

  func redo() {
    guard canRedo else { return }
    let lastCommand = redoHistory.removeLast()
    history.append(lastCommand)
    view?.execute(command: lastCommand)
    delegate?.didUpdateCommandHistory()
  }

  func didUpdateConfig(config: DrawingViewConfiguration) {
    self.config = config
  }
}