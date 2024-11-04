// Created by Igor Klyuzhev in 2024

import UIKit

public protocol DrawingViewInteractor {
  var delegate: DrawingViewDelegate? { get set }
  var canUndo: Bool { get }
  var canRedo: Bool { get }

  func undo()
  func redo()
  func didUpdateConfig(config: DrawingViewConfiguration)
  func produceCurrentSketchImage() -> UIImage?
  func resetForNewSketch()
  func set(frame: UIImage)
}

final class DrawingViewController: DrawingViewOutput {
  weak var view: DrawingViewInput?
  weak var delegate: DrawingViewDelegate?

  var config: DrawingViewConfiguration

  private var history = [DrawingCommand]() {
    didSet {
      let maxSize = 100
      let count = history.count
      if count > maxSize {
        history.removeFirst(count - maxSize)
      }
    }
  }

  private var redoHistory = [DrawingCommand]() {
    didSet {
      let maxSize = 100
      let count = redoHistory.count
      if count > maxSize {
        redoHistory.removeFirst(count - maxSize)
      }
    }
  }

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
    view.execute(command: lastCommand, animated: true)
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
    view.execute(command: lastCommand, animated: true)
    delegate?.didUpdateCommandHistory()
  }

  func didUpdateConfig(config: DrawingViewConfiguration) {
    self.config = config
  }

  func produceCurrentSketchImage() -> UIImage? {
    view?.currentSketchImage()
  }

  func resetForNewSketch() {
    history.removeAll()
    redoHistory.removeAll()
    view?.reset()
    delegate?.didUpdateCommandHistory()
  }

  func set(frame: UIImage) {
    guard let view,
          let image = frame.cgImage
    else { return }
    history.removeAll()
    redoHistory.removeAll()
    view.reset()
    delegate?.didUpdateCommandHistory()
    view.execute(
      command: .slice(
        DrawingSlice(
          image: image,
          rect: CGRect(
            origin: .zero,
            size: view.imageSize
          )
        )
      ),
      animated: false
    )
  }
}
