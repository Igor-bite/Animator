// Created by Igor Klyuzhev in 2024

import IKUI
import IKUtils
import SnapKit
import UIKit

final class PaperUIView: UIView {
  init() {
    super.init(frame: .zero)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup() {
    guard let paperView = PaperView().wrappedInHostingController.view else {
      assertionFailure()
      return
    }
    addSubview(paperView)
    paperView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
}
