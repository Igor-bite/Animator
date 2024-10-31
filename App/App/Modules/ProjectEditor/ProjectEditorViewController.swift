// Created by Igor Klyuzhev in 2024

import UIKit
import SnapKit
import IKUI
import IKUtils
import Combine

protocol ProjectEditorViewInput: AnyObject {}

protocol ProjectEditorViewOutput: AnyObject {
  var state: CurrentValueSubject<ProjectEditorState, Never> { get }
}

enum ToolType: String {
  case pencil
  case brush
  case eraser
}

final class ProjectEditorViewController: UIViewController, ProjectEditorViewInput {
  private let viewModel: ProjectEditorViewOutput
  private var paperView: UIView?
  private lazy var someButton = TapIcon(
    size: .large(),
    icon: Asset.eraser.image,
    selectionType: .icon(Asset.bin.image)
  ).autoLayout()

  private lazy var toolsButtons: SelectableIconsGroup = {
    let icons: [SelectableIconsGroupModel.IconModel] = [
      .init(id: ToolType.pencil.rawValue, icon: Asset.pencil.image),
      .init(id: ToolType.brush.rawValue, icon: Asset.brush.image),
      .init(id: ToolType.eraser.rawValue, icon: Asset.eraser.image)
    ]
    let model = SelectableIconsGroupModel(
      icons: icons,
      intiallySelectedId: ToolType.pencil.rawValue
    )
    let view = SelectableIconsGroup(model: model)
    view.delegate = self
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
    view.addSubviews(someButton, toolsButtons)

    someButton.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
      make.centerX.equalToSuperview()
    }

    let paperView = addSwiftUiView(view: PaperView(), layout: { view in
      view.snp.makeConstraints { make in
        make.leading.equalToSuperview().offset(16)
        make.trailing.equalToSuperview().offset(-16)
        make.top.equalTo(someButton.snp.bottom).offset(24)
        make.bottom.equalTo(toolsButtons.snp.top).offset(-24)
      }
    })
    self.paperView = paperView

    toolsButtons.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
      make.centerX.equalToSuperview()
    }
  }
}

extension ProjectEditorViewController: SelectableIconsGroupDelegate {
  func didSelect(icon: SelectableIconsGroupModel.IconModel) {
    print(ToolType(rawValue: icon.id))
  }
}
