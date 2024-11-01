// Created by Igor Klyuzhev in 2024

import Combine
import IKDrawing
import IKUI
import IKUtils
import SnapKit
import UIKit

protocol ProjectEditorViewInput: AnyObject {}

protocol ProjectEditorViewOutput: AnyObject, TopToolsGroupOutput, BottomToolsGroupOutput {
  var state: CurrentValueSubject<ProjectEditorState, Never> { get }
  var drawingConfig: DrawingViewConfiguration { get }
  var drawingInteractor: DrawingViewInteractor? { get set }
}

final class ProjectEditorViewController: UIViewController, ProjectEditorViewInput {
  private let viewModel: ProjectEditorViewOutput
  private lazy var topToolsView = {
    let view = TopToolsGroup()
    view.output = viewModel
    return view
  }()

  private let paperView = PaperUIView()
  private lazy var drawingView = {
    let (view, interactor) = DrawingViewAssembly.make(
      config: viewModel.drawingConfig
    )
    viewModel.drawingInteractor = interactor
    return view
  }()

  private lazy var bottomToolsView = {
    let model = BottomToolsGroupModel(
      selectedTool: viewModel.drawingConfig.tool,
      selectedColor: viewModel.drawingConfig.color
    )
    let view = BottomToolsGroup(model: model)
    view.output = viewModel
    return view
  }()

  init(viewModel: ProjectEditorViewOutput) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
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
      drawingView,
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

    drawingView.snp.makeConstraints { make in
      make.edges.equalTo(paperView)
    }
    drawingView.smoothCornerRadius = 20

    bottomToolsView.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalToSuperview().offset(-16)
    }
  }
}
