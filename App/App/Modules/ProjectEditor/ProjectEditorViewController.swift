// Created by Igor Klyuzhev in 2024

import UIKit
import IKUI
import IKUtils
import Combine

protocol ProjectEditorViewInput: AnyObject {}

protocol ProjectEditorViewOutput: AnyObject {
  var state: CurrentValueSubject<ProjectEditorState, Never> { get }
}

final class ProjectEditorViewController: UIViewController, ProjectEditorViewInput {
  private let viewModel: ProjectEditorViewOutput
  private lazy var someButton = TapIcon(
    size: .large(),
    icon: Asset.eraser.image
  ).autoLayout()

  init(viewModel: ProjectEditorViewOutput) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Colors.background
    setupUI()
  }

  private func setupUI() {
    view.addSubview(someButton)
    NSLayoutConstraint.activate([
      someButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 4),
      someButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
    ])


    addSwiftUiView(view: PaperView(), layout: { view in
      view.autoLayout()

      NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
        view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
        view.topAnchor.constraint(equalTo: self.someButton.bottomAnchor, constant: 8),
        view.heightAnchor.constraint(equalToConstant: 600)
      ])
    })
  }
}
