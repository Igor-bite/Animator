// Created by Igor Klyuzhev in 2024

import SwiftUI

public struct PaperView: View {
  public init() {}
  
  public var body: some View {
    RoundedRectangle(cornerRadius: 20)
      .fill(.paper())
  }
}

#Preview {
  PaperView()
}

extension ShapeStyle where Self == AnyShapeStyle {
  static func paper() -> Self {
    AnyShapeStyle(
      ShaderLibrary.default.paper(
        .boundingRect
      )
    )
  }
}
