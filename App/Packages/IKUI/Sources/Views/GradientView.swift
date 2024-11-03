// Created by Igor Klyuzhev in 2024

import UIKit

public class GradientView: UIView {
  private var colors: [UIColor]
  private var locations: [Float]?

  override public class var layerClass: Swift.AnyClass {
    CAGradientLayer.self
  }

  public init(
    frame: CGRect = .zero,
    direction: Direction = .vertical(),
    colors: [UIColor],
    locations: [Float]? = nil
  ) {
    self.colors = colors
    self.locations = locations
    super.init(frame: frame)

    guard let gradientLayer = layer as? CAGradientLayer else {
      return
    }

    switch direction {
    case let .vertical(startPoint, endPoint):
      gradientLayer.startPoint = CGPoint(x: 0.5, y: startPoint)
      gradientLayer.endPoint = CGPoint(x: 0.5, y: endPoint)

    case let .horizontal(startPoint, endPoint):
      gradientLayer.startPoint = CGPoint(x: startPoint, y: 0.5)
      gradientLayer.endPoint = CGPoint(x: endPoint, y: 0.5)
    }

    gradientLayer.colors = colors.map(\.cgColor)

    if let locations = locations {
      gradientLayer.locations = locations.map { NSNumber(value: $0) }
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init?(coder:) has not been implemented")
  }

  public func updateGradientColors(
    _ color: [UIColor],
    colorLocations: [Float]? = nil
  ) {
    guard let gradientLayer = layer as? CAGradientLayer else {
      return
    }

    gradientLayer.colors = color.map(\.cgColor)
    if let colorLocations = colorLocations {
      gradientLayer.locations = colorLocations.map { NSNumber(value: $0) }
    }
  }

  override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else { return }
    updateGradientColors(
      colors,
      colorLocations: locations
    )
  }
}

// MARK: - Direction

extension GradientView {
  public enum Direction {
    case vertical(_ startPoint: CGFloat = 0, _ endPoint: CGFloat = 1)
    case horizontal(_ startPoint: CGFloat = 0, _ endPoint: CGFloat = 1)
  }
}
