//
//  StreamMessageReceiveCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 3/28/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class StreamMessageReceiveCell: ChatReceiveMessageCell {
    
    var cellSelectedClosure: () -> Void = {}
    
    @IBAction private func cellDidSelect(_ sender: UIButton) {
        self.cellSelectedClosure()
    }
}
