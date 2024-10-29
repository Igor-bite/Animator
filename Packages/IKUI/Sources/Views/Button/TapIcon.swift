// Created by Igor Klyuzhev in 2024

import UIKit
import IKUtils

public final class TapIcon: UIView {
  // MARK: Properties

  private var size: Size?
  private var icon: UIImage?
  private var tint: UIColor?
  private var selectedTint: UIColor?
  private var action: Action?

  override public var intrinsicContentSize: CGSize {
    CGSize(squareDimension: size?.iconSize ?? 0)
  }

  override public func sizeThatFits(_ size: CGSize) -> CGSize {
    let contentSize = CGSize(squareDimension: self.size?.iconSize ?? 0)
    return CGSize(
      width: min(contentSize.width, size.width),
      height: min(contentSize.height, size.height)
    )
  }

  public var isEnabled: Bool {
    get { iconButton.isEnabled }
    set { iconButton.isEnabled = newValue }
  }

  public var isSelected: Bool {
    get { iconButton.isSelected }
    set {
      iconButton.isSelected = newValue
      updateTintColor()
    }
  }

  // MARK: UI

  private let iconButton: ScalableButton = ScalableButton(
    type: .custom
  ).autoLayout()

  // MARK: Init


  public init() {
    super.init(frame: .zero)
    setupLayout()
  }

  public init(
    size: SizeType,
    icon: UIImage,
    tint: UIColor = Colors.foreground,
    selectedTint: UIColor? = nil
  ) {
    self.size = Size(type: size)
    self.icon = icon
    self.tint = tint
    self.selectedTint = selectedTint ?? tint
    super.init(frame: .zero)
    
    setupLayout()
    iconButton.addTarget(self, action: #selector(didTap), for: .touchUpInside)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Setup

  private func setupLayout() {
    addSubview(iconButton)
    setupConstraints()
    updateButton()
  }

  // MARK: Update

  public func sendActions(for event: UIControl.Event) {
    iconButton.sendActions(for: event)
  }

  public func addAnimationLayerToImage(_ animation: CAAnimation, key: String? = nil) {
    iconButton.imageView?.layer.add(animation, forKey: key)
  }

  public func setUserInteraction(enabled: Bool) {
    iconButton.isUserInteractionEnabled = enabled
  }

  public func setIcon(
    size: SizeType,
    icon: UIImage,
    tint: UIColor = Colors.foreground,
    selectedTint: UIColor? = nil
  ) {
    self.size = Size(type: size)
    self.icon = icon
    self.tint = tint
    self.selectedTint = selectedTint ?? tint

    updateButton()
  }

  public func addAction(action: @escaping Action) {
    self.action = action
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      iconButton.leadingAnchor.constraint(equalTo: leadingAnchor),
      iconButton.trailingAnchor.constraint(equalTo: trailingAnchor),
      iconButton.topAnchor.constraint(equalTo: topAnchor),
      iconButton.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  private func updateButton() {
    updateImage()
    iconButton.isHighlighted = false
    invalidateIntrinsicContentSize()
  }

  private func updateImage() {
    let iconSize = CGSize(squareDimension: size?.iconSize ?? .zero)
    guard
      let icon = icon?.scaledImage(toSize: iconSize).withRenderingMode(.alwaysTemplate)
    else { return }

    iconButton.setImage(icon, for: .normal)
    updateTintColor()
  }

  private func updateTintColor() {
    iconButton.tintColor = isSelected ? selectedTint : tint
  }

  @objc
  private func didTap() {
    isSelected.toggle()
    updateTintColor()
    action?()
  }

  // MARK: Tap

  override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    guard let size else { return false }
    let selfPoint = convert(point, to: self)
    let area = iconButton.bounds
      .inset(
        by: UIEdgeInsets(
          allSidesEqualTo: (size.tapWidth - size.iconSize) / 2
        ).inverted
      )
    let contains = area.contains(selfPoint)
    return contains
  }

  override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard !isHidden, isUserInteractionEnabled else { return nil }
    let selfPoint = convert(point, to: self)
    if self.point(inside: selfPoint, with: event) {
      return iconButton
    } else {
      return nil
    }
  }
}

// MARK: - Settings

extension TapIcon {
  public struct Size: Equatable {
    public var type: SizeType

    var tapWidth: CGFloat {
      switch type {
      case let .small(tap):
        return tap.rawValue
      case let .medium(tap):
        return tap.rawValue
      case let .large(tap):
        return tap.rawValue
      }
    }

    var iconSize: CGFloat {
      switch type {
      case .small:
        return 16
      case .medium:
        return 24
      case .large:
        return 32
      }
    }
  }

  public enum SizeType: CaseIterable, Equatable {
    public static var allCases: [TapIcon.SizeType] = [.small(), .medium(), .large()]

    case small(tapSize: TapZoneSize.Small = .default)
    case medium(tapSize: TapZoneSize.Medium = .default)
    case large(tapSize: TapZoneSize.Large = .default)
  }

  public enum TapZoneSize {
    public enum Small: CGFloat, CaseIterable {
      case `default` = 32
      case size28 = 28
    }

    public enum Medium: CGFloat, CaseIterable {
      case `default` = 40
      case size36 = 36
      case size32 = 32
      case size28 = 28
    }

    public enum Large: CGFloat, CaseIterable {
      case `default` = 44
      case size40 = 40
      case size36 = 36
      case size32 = 32
      case size28 = 28
    }
  }
}