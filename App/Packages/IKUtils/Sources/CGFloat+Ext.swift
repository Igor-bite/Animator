// Created by Igor Klyuzhev in 2024

import CoreGraphics
import UIKit

extension CGFloat {
  public func rounded(toStep step: CGFloat = 1) -> CGFloat {
    Foundation.round(self / step) * step
  }

  public func ceiled(toStep step: CGFloat = 1) -> CGFloat {
    ceil(self / step) * step
  }

  public func floored(toStep step: CGFloat = 1) -> CGFloat {
    Foundation.floor(self / step) * step
  }

  public var roundedToScreenScale: CGFloat {
    rounded(toStep: 1 / UIScreen.main.scale)
  }

  public var flooredToScreenScale: CGFloat {
    floored(toStep: 1 / UIScreen.main.scale)
  }
}
