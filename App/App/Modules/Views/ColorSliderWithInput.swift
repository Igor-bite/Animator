// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

protocol ColorSliderDelegate: AnyObject {
  func valueUpdate(color: UIColor, _ value: CGFloat)
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
    view.addDoneButtonToolbar()
    view.keyboardType = .decimalPad
    view.delegate = self
    view.textColor = Colors.foreground
    view.font = .systemFont(ofSize: 16)
    view.textAlignment = .center
    view.rightViewMode = .always
    view.addTarget(self, action: #selector(textFieldDidChangeValue), for: .editingChanged)
    let rightView = UILabel()
    rightView.text = inputPostfix
    rightView.font = .boldSystemFont(ofSize: 16)
    view.rightView = rightView
    return view
  }()

  private let minValue: Int
  private let maxValue: Int
  private let inputPostfix: String
  private let multiplier: CGFloat
  private let colorSlider: ColorSlider
  private weak var delegate: ColorSliderDelegate?

  override var intrinsicContentSize: CGSize {
    colorSlider.intrinsicContentSize
  }

  public init(
    delegate: ColorSliderDelegate,
    initialValue: CGFloat,
    fromColor: UIColor,
    toColor: UIColor,
    inputPostfix: String,
    multiplier: CGFloat = 100,
    minValue: Int = 0,
    maxValue: Int = 100
  ) {
    self.minValue = minValue
    self.maxValue = maxValue
    self.multiplier = multiplier
    self.inputPostfix = inputPostfix
    self.delegate = delegate
    colorSlider = ColorSlider(
      initialValue: initialValue,
      fromColor: fromColor,
      toColor: toColor
    )
    super.init(frame: .zero)
    colorSlider.delegate = self
    set(value: initialValue)
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
    set(value: CGFloat(num) / multiplier)
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
      make.width.equalTo(52 + inputPostfix.count * 4)
    }

    valueTextField.snp.makeConstraints { make in
      make.leading.top.equalToSuperview().offset(4)
      make.trailing.bottom.equalToSuperview().offset(-4)
    }
  }

  func set(value: CGFloat) {
    let clamped = clamp(Int(value * multiplier), min: minValue, max: maxValue)
    valueTextField.text = String(clamped)
    if clamped == minValue {
      colorSlider.updateValue(0)
    } else if clamped == maxValue {
      colorSlider.updateValue(1)
    } else {
      colorSlider.updateValue(value)
    }
  }

  func valueUpdate(color: UIColor, _ value: CGFloat) {
    valueTextField.text = String(clamp(Int(value * multiplier), min: minValue, max: maxValue))
    delegate?.valueUpdate(color: color, value)
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
    let number = min(maxValue, max(minValue, value))
    set(value: CGFloat(number) / multiplier)
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
