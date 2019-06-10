//
//  StreamMessageSendCell.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/8/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class StreamMessageSendCell: ChatSendMessageCell {

    var cellSelectedClosure: () -> Void = {}
    
    @IBAction private func cellDidSelect(_ sender: UIButton) {
        self.cellSelectedClosure()
    }
}
