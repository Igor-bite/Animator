// Created by Igor Klyuzhev in 2024

import Combine
import UIKit

extension Publishers {
  public static var keyboardHeight: AnyPublisher<CGFloat, Never> {
    let willShow: Publishers.Map<NotificationCenter.Publisher, CGFloat> = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
      .map(\._keyboardHeight)

    let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
      .map { _ in CGFloat(0) }

    return MergeMany(willShow, willHide)
      .eraseToAnyPublisher()
  }

  public static var keyboardVisibility: AnyPublisher<Bool, Never> {
    keyboardHeight
      .map { $0 > 0 ? true : false }
      .eraseToAnyPublisher()
  }
}

extension Notification {
  // name collision
  fileprivate var _keyboardHeight: CGFloat {
    (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
  }
}
