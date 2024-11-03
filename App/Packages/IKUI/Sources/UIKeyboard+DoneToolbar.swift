// Created by Igor Klyuzhev in 2024

import UIKit

extension UITextView {
  public func addDoneButtonToolbar() {
    inputAccessoryView = makeDoneToolbar(
      target: self,
      action: #selector(resignFirstResponder)
    )
  }
}

extension UITextField {
  public func addDoneButtonToolbar() {
    inputAccessoryView = makeDoneToolbar(
      target: self,
      action: #selector(resignFirstResponder)
    )
  }
}

private func makeDoneToolbar(
  target: Any?,
  action: Selector?
) -> UIView {
  let doneToolbar = UIToolbar()
  doneToolbar.sizeToFit()

  let flexSpace = UIBarButtonItem(
    barButtonSystemItem: .flexibleSpace,
    target: nil,
    action: nil
  )
  let done = UIBarButtonItem(
    barButtonSystemItem: .done,
    target: target,
    action: action
  )

  doneToolbar.items = [flexSpace, done]

  return doneToolbar
}
