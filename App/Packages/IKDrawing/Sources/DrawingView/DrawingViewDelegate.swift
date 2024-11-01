// Created by Igor Klyuzhev in 2024

import Foundation

public protocol DrawingViewDelegate: AnyObject {
  func didUpdateCommandHistory()
}
