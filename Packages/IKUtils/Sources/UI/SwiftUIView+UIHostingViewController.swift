// Created by Igor Klyuzhev in 2024

import Foundation
import SwiftUI

extension SwiftUI.View {
  var wrappedInHostingController: UIViewController {
    UIHostingController(rootView: self)
  }
}
