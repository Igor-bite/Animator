// Created by Igor Klyuzhev in 2024

import Combine
import UIKit

extension Publishers {
  public static var keyboardFrame: AnyPublisher<CGRect, Never> {
    let willShow: Publishers.Map<NotificationCenter.Publisher, CGRect> = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
      .map(\._keyboardFrame)

    let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
      .map { _ in CGRect.zero }

    return MergeMany(willShow, willHide)
      .eraseToAnyPublisher()
  }

  public static var keyboardHeight: AnyPublisher<CGFloat, Never> {
    keyboardFrame
      .map(\.height)
      .eraseToAnyPublisher()
  }

  public static var keyboardVisibility: AnyPublisher<Bool, Never> {
    keyboardHeight
      .map { $0 > 0 ? true : false }
      .eraseToAnyPublisher()
  }
}

extension Notification {
  fileprivate var _keyboardFrame: CGRect {
    (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
  }
}
