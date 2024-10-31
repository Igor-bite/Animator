// Created by Igor Klyuzhev in 2024

import UIKit
import IKUtils
import IKUI
import SnapKit

final class PaperUIView: UIView {
  init() {
    super.init(frame: .zero)
    setup()
  }
  
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
