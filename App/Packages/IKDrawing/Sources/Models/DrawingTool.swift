// Created by Igor Klyuzhev in 2024

import Foundation

public enum DrawingTool: Equatable {
  case pen
  case brush
  case eraser
  case geometry(GeometryObject)

  public var id: String {
    switch self {
    case .pen:
      "pen"
    case .brush:
      "brush"
    case .eraser:
      "eraser"
    case let .geometry(geometryObject):
      geometryObject.rawValue
    }
  }
}

public enum GeometryObject: String {
  case triangle
  case circle
  case square
  case arrow
}
