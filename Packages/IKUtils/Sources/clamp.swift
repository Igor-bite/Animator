// Created by Igor Klyuzhev in 2024

import Foundation

public func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
  min(max(value, minValue), maxValue)
}
