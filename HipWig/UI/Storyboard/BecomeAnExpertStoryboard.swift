//
//  BecomeAnExpertStoryborad.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/7/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

class BecomeAnExpertStoryboard: UIStoryboard {
    
    class func showStartBecomeAnExpert(from source: UIViewController) {
        let viewController: StartBecomeAnExpertViewController = instantiate()
        source.navigationController?.pushViewController(viewController, animated: true)
    }
    
    class func showBecomeAnExpertFlow(from source: UIViewController, with user: InternalExpert) {
        let viewController: DefineAnExpertContainerViewController = instantiate()
        viewController.user = user
        source.navigationController?.pushViewController(viewController, animated: true)
    }
}
