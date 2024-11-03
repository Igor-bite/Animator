// Created by Igor Klyuzhev in 2024

import Combine
import IKDrawing
import IKUI
import IKUtils
import SnapKit
import UIKit

protocol ProjectEditorViewInput: AnyObject {
  func updateTopControls()
  func updateLineWidthPreview()
  func updateLineWidthPreviewVisibility(isVisible: Bool)
  func updateLineWidthAlpha()
  func updateColorSelector(shouldClose: Bool)
}

protocol ProjectEditorViewOutput: AnyObject,
  TopToolsGroupOutput,
  BottomToolsGroupOutput,
  LineWidthSelectorDelegate,
  ColorSelectorViewDelegate
{
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

  private lazy var lineWidthSelector = LineWidthSelector(
    delegate: viewModel,
    initialValue: (viewModel.drawingConfig.lineWidth - 4) / 100
  )

  private lazy var lineWidthPreview = {
    let view = UIView()
    view.backgroundColor = Colors.background
    view.layer.cornerRadius = viewModel.drawingConfig.lineWidth / 2
    view.isUserInteractionEnabled = false
    view.alpha = .zero
    return view
  }()

  private var lineWidthPreviewSize: Constraint?
  private var lineWidthSelectorLeading: Constraint?

  private lazy var colorSelectorView = {
    let view = ColorSelectorView(
      initialColor: viewModel.drawingConfig.color
    )
    view.alpha = 0
    view.delegate = viewModel
    return view
  }()

  private var isColorSelectorVisible = false

  private var bag = CancellableBag()

  init(viewModel: ProjectEditorViewOutput) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
    setupBinding()
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

  func updateTopControls() {
    topToolsView.updateUI()
  }

  func updateLineWidthPreview() {
    UIView.performWithoutAnimation {
      lineWidthPreview.layer.cornerRadius = viewModel.drawingConfig.lineWidth / 2
    }
    lineWidthPreviewSize?.update(offset: viewModel.drawingConfig.lineWidth)
  }

  func updateLineWidthPreviewVisibility(isVisible: Bool) {
    let t = isVisible ? 46.0 : 0

    UIView.animate(
      withDuration: 0.2,
      delay: .zero,
      options: .curveEaseInOut
    ) {
      self.lineWidthPreview.alpha = isVisible ? 1 : 0
      self.lineWidthSelector.transform.tx = t
    }
  }

  func updateLineWidthAlpha() {
    let action = {
      self.lineWidthSelector.alpha = self.viewModel.drawingConfig.canDraw ? 1 : 0
    }

    if UIView.inheritedAnimationDuration > 0 {
      action()
      return
    }

    UIView.animate(
      withDuration: 0.2,
      delay: .zero,
      options: .curveEaseInOut
    ) {
      action()
    }
  }

  func updateColorSelector(shouldClose: Bool) {
    let isNowVisible = isColorSelectorVisible
    let shouldBeVisible = !isNowVisible || (isNowVisible && !shouldClose)
    isColorSelectorVisible = shouldBeVisible
    bottomToolsView.updateColorSelector(isSelected: shouldBeVisible)
    bottomToolsView.updateColorSelector(color: viewModel.drawingConfig.color)

    UIView.animate(
      withDuration: 0.2,
      delay: .zero,
      options: .curveEaseInOut
    ) {
      self.colorSelectorView.alpha = shouldBeVisible ? 1 : 0
    }
  }

  private func setupBinding() {
    viewModel.state.sink { [weak self] state in
      self?.handleStateUpdate(to: state)
    }.store(in: bag)
  }

  private func handleStateUpdate(to state: ProjectEditorState) {
    let action = {
      switch state {
      case .readyForDrawing:
        self.updateLineWidthAlpha()
        self.topToolsView.alpha = 1
        self.bottomToolsView.alpha = 1
        self.colorSelectorView.alpha = self.isColorSelectorVisible ? 1 : 0
      case .drawingInProgress:
        self.lineWidthSelector.alpha = 0
        self.topToolsView.alpha = 0
        self.bottomToolsView.alpha = 0
        if self.isColorSelectorVisible {
          self.updateColorSelector(shouldClose: true)
        }
      case .managingFrames:
        break
      case .playing:
        break
      }
    }

    UIView.animate(
      withDuration: 0.2,
      delay: .zero,
      options: .curveEaseInOut
    ) {
      action()
    }
  }

  private func setupUI() {
    view.addSubviews(
      topToolsView,
      paperView,
      drawingView,
      bottomToolsView,
      lineWidthSelector,
      lineWidthPreview,
      colorSelectorView
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

    lineWidthSelector.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      self.lineWidthSelectorLeading = make.leading.equalToSuperview().offset(-112).constraint
    }

    lineWidthPreview.snp.makeConstraints { make in
      make.centerX.centerY.equalToSuperview()
      self.lineWidthPreviewSize = make.height.width.equalTo(0).offset(viewModel.drawingConfig.lineWidth).constraint
    }

    colorSelectorView.snp.makeConstraints { make in
      make.bottom.equalTo(bottomToolsView.snp.top).offset(-16)
      make.centerX.equalToSuperview()
    }
  }
}
