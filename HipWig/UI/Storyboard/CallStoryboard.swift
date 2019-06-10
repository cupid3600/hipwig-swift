//
//  CallStoryboard.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 4/8/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class CallStoryboard: UIStoryboard {

    class var incomingCallViewController: AcceptStreamViewController {
        let viewController: AcceptStreamViewController = instantiate(customID: kAcceptStreamScreenID)
        viewController.hidesBottomBarWhenPushed = true
        
        return viewController
    }
    
    class var outgoingCallViewController: StartStreamViewController {
        let viewController: StartStreamViewController = instantiate(customID: kStartStreamScreenID)
        return viewController
    }
    
    class func showStream(data: StreamData, from target: UINavigationController) {
        let viewController: StreamViewController = instantiate(customID: kStreamScreenID)
        viewController.streamData = data
        
        target.pushViewController(viewController, animated: false)
        target.viewControllers = [viewController]
    }
    
    class var startVideoChatViewController: StartStreamViewController {
        let viewController: StartStreamViewController = instantiate(customID: kStartStreamScreenID)
        viewController.hidesBottomBarWhenPushed = true

        return viewController
    } 
}
