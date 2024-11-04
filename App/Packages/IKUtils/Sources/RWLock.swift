// Created by Igor Klyuzhev in 2024

import Foundation

public final class RWLock {
  public init() {
    pthread_rwlock_init(&lock, nil)
  }

  deinit {
    pthread_rwlock_destroy(&lock)
  }

  public func read<T>(_ block: () -> T) -> T {
    pthread_rwlock_rdlock(&lock)
    defer { pthread_rwlock_unlock(&lock) }
    return block()
  }

  public func readWrite<T>(_ block: () -> T) -> T {
    pthread_rwlock_wrlock(&lock)
    defer { pthread_rwlock_unlock(&lock) }
    return block()
  }

  private var lock = pthread_rwlock_t()
}

@propertyWrapper
public struct RWLocked<T> {
  public init(wrappedValue: T) {
    value = wrappedValue
  }

  public var wrappedValue: T {
    get {
      lock.read {
        value
      }
    }
    set {
      lock.readWrite {
        value = newValue
      }
    }
  }

  @discardableResult
  public mutating func readWrite(_ block: (inout T) -> Void) -> (oldValue: T, newValue: T) {
    lock.readWrite {
      let old = value
      block(&value)
      return (old, value)
    }
  }

  private var value: T
  private let lock = RWLock()
}
