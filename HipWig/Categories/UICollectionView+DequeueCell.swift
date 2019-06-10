//
//  UICollectionView+DequeueCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 29.01.2019.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func dequeueHeaderView<T: UICollectionReusableView> (indexPath: IndexPath) -> T {
        return self.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                     withReuseIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
    
    func dequeueFooterView<T: UICollectionReusableView> (indexPath: IndexPath) -> T {
        return self.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                     withReuseIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
    
    func dequeueSupplementaryView<T: UICollectionReusableView> (indexPath: IndexPath, with kind: String) -> T {
        return self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
    
    func dequeueReusableCell<T: UICollectionViewCell> (indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
    
    func registerNib(with celltype: UICollectionViewCell.Type) {
        self.register(celltype.nib, forCellWithReuseIdentifier: celltype.reuseIdentifier)
    }
    
    func registerNib(with celltype: UICollectionReusableView.Type, forKind kind: String) {
        self.register(celltype.nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: celltype.reuseIdentifier)
    }
}

extension UITableView {
    
    func dequeueReusableCell<T: UITableViewCell> (indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
    
    func dequeueReusableView<T: UITableViewHeaderFooterView> () -> T {
        return self.dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as! T
    }
    
    func registerNib(with celltype: UITableViewCell.Type) {
        self.register(celltype.nib, forCellReuseIdentifier: celltype.reuseIdentifier)
    }
    
    func registerNibForHeaderFooter(with celltype: UITableViewHeaderFooterView.Type) {
        self.register(celltype.nib, forHeaderFooterViewReuseIdentifier: celltype.reuseIdentifier)
    }
}

