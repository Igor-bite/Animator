// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

protocol ColorSliderDelegate: AnyObject {
  func valueUpdate(_ value: CGFloat)
}

final class ColorSliderWithInput: UIView, ColorSliderDelegate {
  private lazy var textFieldContainer = {
    let view = UIView()
    view.smoothCornerRadius = 4
    view.backgroundColor = Colors.background
    return view
  }()

  private lazy var valueTextField = {
    let view = UITextField()
    view.keyboardType = .decimalPad
    view.delegate = self
    view.textColor = Colors.foreground
    view.font = .systemFont(ofSize: 16)
    view.textAlignment = .center
    view.rightViewMode = .always
    view.addTarget(self, action: #selector(textFieldDidChangeValue), for: .editingChanged)
    let rightView = UILabel()
    rightView.text = "%"
    rightView.font = .boldSystemFont(ofSize: 16)
    view.rightView = rightView
    return view
  }()

  private let colorSlider: ColorSlider
  private weak var delegate: ColorSliderDelegate?

  public init(
    delegate: ColorSliderDelegate,
    initialValue: CGFloat,
    color: UIColor
  ) {
    self.delegate = delegate
    colorSlider = ColorSlider(
      initialValue: initialValue,
      color: color
    )
    super.init(frame: .zero)
    colorSlider.delegate = self
    set(initialValue: initialValue)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    guard let text = valueTextField.text,
          let num = Int(text)
    else { return }
    colorSlider.updateValue(CGFloat(num) / 100)
  }

  private func setupUI() {
    addSubviews(colorSlider, textFieldContainer)
    textFieldContainer.addSubview(valueTextField)

    colorSlider.snp.makeConstraints { make in
      make.top.bottom.leading.equalToSuperview()
      make.trailing.equalTo(valueTextField.snp.leading).offset(-16)
    }

    textFieldContainer.snp.makeConstraints { make in
      make.trailing.equalToSuperview()
      make.top.bottom.equalToSuperview()
      make.width.equalTo(56)
    }

    valueTextField.snp.makeConstraints { make in
      make.leading.top.equalToSuperview().offset(4)
      make.trailing.bottom.equalToSuperview().offset(-4)
    }
  }

  private func set(initialValue: CGFloat) {
    valueTextField.text = String(Int(initialValue * 100))
  }

  @objc
  private func textFieldDidChangeValue() {
    var text = valueTextField.text ?? "0"
    if text.isEmpty {
      text = "0"
    }
    guard let value = Int(text) else {
      assertionFailure()
      return
    }
    let number = min(100, max(0, value))
    valueTextField.text = String(number)
    colorSlider.updateValue(CGFloat(number) / 100)
  }

  func valueUpdate(_ value: CGFloat) {
    valueTextField.text = String(Int(value * 100))
    delegate?.valueUpdate(value)
  }
}

extension ColorSliderWithInput: UITextFieldDelegate {
  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    let currentString = (textField.text ?? "") as NSString
    let newString = currentString.replacingCharacters(in: range, with: string)
    if newString.isEmpty {
      return true
    }
    return Int(newString) != nil
  }
}
