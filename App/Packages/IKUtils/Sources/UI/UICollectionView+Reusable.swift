// Created by Igor Klyuzhev in 2024

import UIKit

extension UICollectionView {
  public func dequeueReusableCell<T: UICollectionViewCell>(
    of type: T.Type = T.self,
    for indexPath: IndexPath
  ) -> T? {
    dequeueReusableCell(withReuseIdentifier: "\(type)", for: indexPath) as? T
  }

  public func registerCell<T: UICollectionViewCell>(of type: T.Type = T.self) {
    register(type.self, forCellWithReuseIdentifier: "\(type)")
  }
}
