// Created by Igor Klyuzhev in 2024

import Foundation

extension Array {
  public subscript(safe index: Int) -> Element? {
    guard index >= 0, index < endIndex else {
      return nil
    }

    return self[index]
  }
}
