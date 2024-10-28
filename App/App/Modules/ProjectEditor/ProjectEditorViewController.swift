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

    addSwiftUiView(view: PaperView(), layout: { view in
      view.translatesAutoresizingMaskIntoConstraints = false

      NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
        view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
        view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        view.heightAnchor.constraint(equalToConstant: 600)
      ])
    })
  }
}
