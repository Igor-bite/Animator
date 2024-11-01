// Created by Igor Klyuzhev in 2024

import UIKit

enum DrawingCommand {
  case addLayer(CALayer)
  case removeLayer(CALayer)

  var inverted: DrawingCommand {
    switch self {
    case let .addLayer(layer):
      .removeLayer(layer)
    case let .removeLayer(layer):
      .addLayer(layer)
    }
  }
}
