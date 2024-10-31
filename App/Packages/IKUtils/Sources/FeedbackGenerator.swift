// Created by Igor Klyuzhev in 2024

import UIKit

final class FeedbackGenerator {
  private static let selectionFeedbackGenerator = UISelectionFeedbackGenerator()

  static func selectionChanged() {
    selectionFeedbackGenerator.prepare()
    selectionFeedbackGenerator.selectionChanged()
  }
}
