// Created by Igor Klyuzhev in 2024

import Foundation

public protocol DrawingViewDelegate: AnyObject {
  func didUpdateCommandHistory()
  func didStartDrawing()
  func didEndDrawing()
}
