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
  func updatePreviousFrame(with image: UIImage?)
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
  var playerInteractor: FramesPlayerInteractor? { get set }
  var drawingAreaSize: CGSize { get set }
}

final class ProjectEditorViewController: UIViewController {
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
    view.smoothCornerRadius = Constants.drawingViewCornerRadius
    return view
  }()

  private lazy var framesPlayerView = {
    let (view, interactor) = FramesPlayerAssembly.make(
      with: FramesPlayerConfig(fps: 10)
    )
    viewModel.playerInteractor = interactor
    view.smoothCornerRadius = Constants.drawingViewCornerRadius
    view.clipsToBounds = true
    return view
  }()

  private let previousFrameImageView = {
    let view = UIImageView()
    view.smoothCornerRadius = Constants.drawingViewCornerRadius
    view.clipsToBounds = true
    view.alpha = 0.5
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
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Colors.background
    setupUI()
    setupBinding()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    viewModel.drawingAreaSize = drawingView.bounds.size
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
        UIView.performWithoutAnimation {
          self.framesPlayerView.isHidden = true
          self.framesPlayerView.alpha = 0
        }
        self.updateLineWidthAlpha()
        self.topToolsView.alpha = 1
        self.topToolsView.isHidden = false
        self.bottomToolsView.alpha = 1
        self.bottomToolsView.isHidden = false
        self.previousFrameImageView.alpha = 0.5
        self.previousFrameImageView.isHidden = false
        self.drawingView.alpha = 1
        self.drawingView.isHidden = false
        self.colorSelectorView.alpha = self.isColorSelectorVisible ? 1 : 0
      case .drawingInProgress:
        self.lineWidthSelector.alpha = 0
        self.lineWidthSelector.isHidden = true
        self.topToolsView.alpha = 0
        self.topToolsView.isHidden = true
        self.bottomToolsView.alpha = 0
        self.bottomToolsView.isHidden = true
        self.previousFrameImageView.alpha = 0.5
        self.previousFrameImageView.isHidden = false

        if self.isColorSelectorVisible {
          self.updateColorSelector(shouldClose: true)
        }
      case .managingFrames:
        break
      case .playing:
        UIView.performWithoutAnimation {
          self.framesPlayerView.isHidden = false
          self.framesPlayerView.alpha = 1
        }
        self.lineWidthSelector.alpha = 0
        self.lineWidthSelector.isHidden = true
        self.previousFrameImageView.alpha = 0
        self.previousFrameImageView.isHidden = true
        self.bottomToolsView.alpha = 0
        self.bottomToolsView.isHidden = true
        self.drawingView.alpha = 0
        self.drawingView.isHidden = true

        if self.isColorSelectorVisible {
          self.updateColorSelector(shouldClose: true)
        }
      }
    }

    if state.needsAnimatedChange {
      UIView.animate(
        withDuration: 0.2,
        delay: .zero,
        options: .curveEaseInOut
      ) {
        action()
      }
    } else {
      action()
    }
  }

  private func setupUI() {
    view.addSubviews(
      topToolsView,
      paperView,
      framesPlayerView,
      previousFrameImageView,
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
    previousFrameImageView.snp.makeConstraints { make in
      make.edges.equalTo(paperView)
    }
    framesPlayerView.snp.makeConstraints { make in
      make.edges.equalTo(paperView)
    }

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

extension ProjectEditorViewController: ProjectEditorViewInput {
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
      self.lineWidthSelector.isHidden = self.viewModel.drawingConfig.canDraw ? false : true
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
      self.colorSelectorView.isHidden = shouldBeVisible ? false : true
    }
  }

  func updatePreviousFrame(with image: UIImage?) {
    previousFrameImageView.image = image
  }
}

private enum Constants {
  static let drawingViewCornerRadius = 20.0
}
