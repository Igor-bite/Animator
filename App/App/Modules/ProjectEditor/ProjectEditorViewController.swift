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
  func updateGeometrySelector()
  func updatePreviousFrame(with image: UIImage?)
  func askToRemoveAll(removeAction: @escaping () -> Void)
  func showExportLoadingAlert()
  func closeExportLoadingAlert()
}

protocol ProjectEditorViewOutput: AnyObject,
  TopToolsGroupOutput,
  BottomToolsGroupOutput,
  LineWidthSelectorDelegate,
  ColorSelectorViewDelegate,
  LayersPreviewDelegate,
  GeometrySelectorViewDelegate
{
  var state: CurrentValueSubject<ProjectEditorState, Never> { get }
  var drawingConfig: DrawingViewConfiguration { get }
  var drawingInteractor: DrawingViewInteractor? { get set }
  var playerConfig: FramesPlayerConfig { get }
  var playerInteractor: FramesPlayerInteractor? { get set }
  var drawingAreaSize: CGSize { get set }

  func generateFrames(count: Int)
  func cancelGenerationFlow()
  func cancelExport()
}

protocol StateDependentView {
  func stateDidUpdate(newState: ProjectEditorState)
}

final class ProjectEditorViewController: UIViewController {
  private let viewModel: ProjectEditorViewOutput
  private lazy var topToolsView = {
    let view = TopToolsGroup()
    view.output = viewModel
    return view
  }()

  private let paperView = {
    let view = PaperUIView()
    view.smoothCornerRadius = Constants.drawingViewCornerRadius
    return view
  }()

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
      with: viewModel.playerConfig
    )
    viewModel.playerInteractor = interactor
    view.smoothCornerRadius = Constants.drawingViewCornerRadius
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

  private lazy var geometrySelectorView = {
    let view = GeometrySelectorView()
    view.alpha = 0
    view.delegate = viewModel
    return view
  }()

  private lazy var layersPreviewScrollView = {
    let view = LayersPreviewScrollView()
    view.delegate = viewModel
    view.alpha = 0
    return view
  }()

  private var loadingViewController: UIViewController?
  private var isColorSelectorVisible = false
  private var isGeometrySelectorVisible = false

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
    layersPreviewScrollView.itemAspectRatio = paperView.frame.height / paperView.frame.width
  }

  private func setupBinding() {
    viewModel.state.sink { [weak self] state in
      self?.handleStateUpdate(to: state)
    }.store(in: bag)
  }

  private func handleStateUpdate(to state: ProjectEditorState) {
    let action = {
      self.topToolsView.stateDidUpdate(newState: state)
      self.bottomToolsView.stateDidUpdate(newState: state)
      self.layersPreviewScrollView.stateDidUpdate(newState: state)

      switch state {
      case .readyForDrawing:
        UIView.performWithoutAnimation {
          self.framesPlayerView.alpha = 0
        }
        self.updateLineWidthAlpha()
        self.previousFrameImageView.alpha = 0.5
        self.drawingView.alpha = 1
        self.colorSelectorView.alpha = self.isColorSelectorVisible ? 1 : 0
        self.geometrySelectorView.alpha = self.isGeometrySelectorVisible ? 1 : 0
        self.loadingViewController?.dismiss(animated: true)
      case .drawingInProgress:
        self.lineWidthSelector.alpha = 0
        self.previousFrameImageView.alpha = 0.5

        if self.isColorSelectorVisible {
          self.updateColorSelector(shouldClose: true)
        }
        if self.isGeometrySelectorVisible {
          self.updateGeometrySelector()
        }
        self.loadingViewController?.dismiss(animated: true)
      case .managingFrames:
        self.previousFrameImageView.alpha = 0.5
        self.lineWidthSelector.alpha = 0
        if self.isColorSelectorVisible {
          self.updateColorSelector(shouldClose: true)
        }
        if self.isGeometrySelectorVisible {
          self.updateGeometrySelector()
        }
        self.drawingView.alpha = 1
        self.loadingViewController?.dismiss(animated: true)
      case .playing:
        UIView.performWithoutAnimation {
          self.framesPlayerView.alpha = 1
        }
        self.lineWidthSelector.alpha = 0
        self.previousFrameImageView.alpha = 0
        self.drawingView.alpha = 0

        if self.isColorSelectorVisible {
          self.updateColorSelector(shouldClose: true)
        }
        if self.isGeometrySelectorVisible {
          self.updateGeometrySelector()
        }
        self.loadingViewController?.dismiss(animated: true)
      case let .generationFlow(generationFlowState):
        switch generationFlowState {
        case .loading:
          self.loadingViewController = self.showGenerationInProgressState()
        case .settings:
          self.showSettingsAlert()
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

  private func showGenerationInProgressState() -> UIViewController {
    let alertController = UIAlertController(
      title: "Генерируем",
      message: nil,
      preferredStyle: .alert
    )

    let indicator = UIActivityIndicatorView(frame: alertController.view.bounds)
    indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    alertController.view.addSubview(indicator)
    indicator.isUserInteractionEnabled = false
    indicator.startAnimating()

    let cancelAction = UIAlertAction(
      title: "Отмена",
      style: .default
    ) { _ in
      self.viewModel.cancelGenerationFlow()
    }

    alertController.addAction(cancelAction)

    present(alertController, animated: true, completion: nil)
    return alertController
  }

  private func showSettingsAlert(withError: Bool = false) {
    let alertController = UIAlertController(
      title: "\(withError ? "Ошибка ввода\n\n" : "")Сколько фреймов сгененрировать?",
      message: "Введите число от 1 до 100000",
      preferredStyle: .alert
    )

    alertController.addTextField { textField in
      textField.placeholder = "10"
      textField.text = "10"
    }

    let cancelAction = UIAlertAction(title: "Отменить", style: .cancel) { _ in
      self.viewModel.cancelGenerationFlow()
    }

    let submitAction = UIAlertAction(
      title: "Сгенерировать",
      style: .default
    ) { _ in
      guard let text = alertController.textFields?.first?.text,
            let framesCount = Int(text),
            framesCount <= 100000
      else {
        DispatchQueue.main.async { [weak self] in
          self?.showSettingsAlert(withError: true)
        }
        return
      }
      self.viewModel.generateFrames(count: framesCount)
    }

    alertController.addAction(cancelAction)
    alertController.addAction(submitAction)

    present(alertController, animated: true, completion: nil)
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
      colorSelectorView,
      geometrySelectorView,
      layersPreviewScrollView
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
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-4)
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

    geometrySelectorView.snp.makeConstraints { make in
      make.bottom.equalTo(bottomToolsView.snp.top).offset(-16)
      make.centerX.equalToSuperview()
    }

    layersPreviewScrollView.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      make.leading.equalToSuperview()
      make.trailing.equalToSuperview()
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
    if isGeometrySelectorVisible {
      updateGeometrySelector()
    } else {
      bottomToolsView.updateShapeSelector(object: viewModel.drawingConfig.selectedShape)
    }
    if viewModel.drawingConfig.selectedShape == nil {
      geometrySelectorView.deselect()
    }
  }

  func updateColorSelector(shouldClose: Bool) {
    if isGeometrySelectorVisible {
      updateGeometrySelector()
    }
    let isNowVisible = isColorSelectorVisible
    let shouldBeVisible = !isNowVisible || (isNowVisible && !shouldClose)
    isColorSelectorVisible = shouldBeVisible
    bottomToolsView.updateColorSelector(isSelected: shouldBeVisible)
    bottomToolsView.updateColorSelector(color: viewModel.drawingConfig.color)
    if !shouldBeVisible {
      colorSelectorView.colorSelectorDidClose()
    }

    UIView.animate(
      withDuration: 0.2,
      delay: .zero,
      options: .curveEaseInOut
    ) {
      self.colorSelectorView.alpha = shouldBeVisible ? 1 : 0
    }
  }

  func updateGeometrySelector() {
    if isColorSelectorVisible {
      updateColorSelector(shouldClose: true)
    }
    let isNowVisible = isGeometrySelectorVisible
    let shouldBeVisible = !isNowVisible
    isGeometrySelectorVisible = shouldBeVisible
    bottomToolsView.updateShapeSelector(isSelected: shouldBeVisible)
    bottomToolsView.updateShapeSelector(object: viewModel.drawingConfig.selectedShape)

    UIView.animate(
      withDuration: 0.2,
      delay: .zero,
      options: .curveEaseInOut
    ) {
      self.geometrySelectorView.alpha = shouldBeVisible ? 1 : 0
    }
  }

  func updatePreviousFrame(with image: UIImage?) {
    previousFrameImageView.image = image
  }

  func askToRemoveAll(removeAction: @escaping () -> Void) {
    let alertController = UIAlertController(
      title: "Вы уверены, что хотите удалить все слои?",
      message: nil,
      preferredStyle: .alert
    )

    let cancelAction = UIAlertAction(title: "Отменить", style: .cancel) { _ in }

    let submitAction = UIAlertAction(
      title: "Удалить",
      style: .destructive
    ) { _ in
      removeAction()
    }

    alertController.addAction(cancelAction)
    alertController.addAction(submitAction)

    present(alertController, animated: true, completion: nil)
  }

  func showExportLoadingAlert() {
    let alertController = UIAlertController(
      title: "Экспортируем",
      message: nil,
      preferredStyle: .alert
    )

    let indicator = UIActivityIndicatorView(frame: alertController.view.bounds)
    indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    alertController.view.addSubview(indicator)
    indicator.isUserInteractionEnabled = false
    indicator.startAnimating()

    let cancelAction = UIAlertAction(
      title: "Отменить",
      style: .destructive
    ) { _ in
      self.viewModel.cancelExport()
    }

    alertController.addAction(cancelAction)

    present(alertController, animated: true, completion: nil)
    loadingViewController = alertController
  }

  func closeExportLoadingAlert() {
    loadingViewController?.dismiss(animated: true)
  }
}

private enum Constants {
  static let drawingViewCornerRadius = 20.0
}
