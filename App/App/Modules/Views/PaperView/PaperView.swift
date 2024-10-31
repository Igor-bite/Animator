// Created by Igor Klyuzhev in 2024

import SwiftUI

public struct PaperView: View {
  @Environment(\.colorScheme) var colorScheme

  public init() {}

  public var body: some View {
    RoundedRectangle(cornerRadius: 20)
      .fill(
        .paper(isLightTheme: colorScheme == .light)
      )
  }
}

#Preview {
  PaperView()
}

extension ShapeStyle where Self == AnyShapeStyle {
  static func paper(isLightTheme: Bool) -> Self {
    AnyShapeStyle(
      ShaderLibrary.default.paper(
        .boundingRect,
        .float(isLightTheme ? 1 : 0)
      )
    )
  }
}
