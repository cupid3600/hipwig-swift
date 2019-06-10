//
//  TableView+EmptyView.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 6/4/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func setEmptyView(view: UIView) {
        let frameToPlace = CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height)
        let emptyView = UIView(frame: frameToPlace)
        emptyView.place(view)
        
        self.backgroundView = emptyView
    }
    
    func layoutBackgroundView() {
        self.backgroundView?.frame = self.frame
        self.backgroundView?.layoutSubviews()
    }
    
    func restoreEmptyView() {
        self.backgroundView = nil
    }
}
