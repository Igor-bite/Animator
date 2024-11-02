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

  func didStartDrawing() {
    delegate?.didStartDrawing()
  }

  func didEndDrawing() {
    delegate?.didEndDrawing()
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
    guard canUndo,
          let view
    else { return }

    let lastCommand = history.removeLast()
    if let slice = view.slice() {
      redoHistory.append(.slice(slice))
    }
    view.execute(command: lastCommand)
    delegate?.didUpdateCommandHistory()
  }

  func redo() {
    guard canRedo,
          let view
    else { return }

    let lastCommand = redoHistory.removeLast()
    if let slice = view.slice() {
      history.append(.slice(slice))
    } else {
      history.append(.clearAll)
    }
    view.execute(command: lastCommand)
    delegate?.didUpdateCommandHistory()
  }

  func didUpdateConfig(config: DrawingViewConfiguration) {
    self.config = config
  }
}
