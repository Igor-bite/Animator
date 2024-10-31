// Created by Igor Klyuzhev in 2024

import UIKit
import SnapKit
import IKUI
import IKUtils
import Combine

protocol ProjectEditorViewInput: AnyObject {}

protocol ProjectEditorViewOutput: AnyObject, TopToolsGroupOutput, BottomToolsGroupOutput {
  var state: CurrentValueSubject<ProjectEditorState, Never> { get }
}

enum ToolType: String {
  case pencil
  case brush
  case eraser
}

final class ProjectEditorViewController: UIViewController, ProjectEditorViewInput {
  private let viewModel: ProjectEditorViewOutput
  private lazy var topToolsView = {
    let view = TopToolsGroup()
    view.output = viewModel
    return view
  }()
  private let paperView = PaperUIView()
  private lazy var bottomToolsView = {
    let model = BottomToolsGroupModel(selectedTool: .pencil, selectedColor: .red)
    let view = BottomToolsGroup(model: model)
    view.output = viewModel
    return view
  }()

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
    view.addSubviews(
      topToolsView,
      paperView,
      bottomToolsView
    )

    topToolsView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalToSuperview().offset(-16)
    }

    paperView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalToSuperview().offset(-16)
      make.top.equalTo(topToolsView.snp.bottom).offset(24)
      make.bottom.equalTo(bottomToolsView.snp.top).offset(-24)
    }

    bottomToolsView.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalToSuperview().offset(-16)
    }
  }
}
