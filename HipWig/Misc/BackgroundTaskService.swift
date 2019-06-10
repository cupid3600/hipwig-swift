//
//  BackgroundTaskService.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 3/27/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

typealias BackgroundTaskIdentifier = String

protocol BackgroundTaskService : class {
    func startTask() -> BackgroundTaskIdentifier
    func endTask(with identifier: BackgroundTaskIdentifier)
}

class BackgroundTaskServiceImplementation: BackgroundTaskService {
    
    private struct Task {
        let id: String
        let taskIndentifier: UIBackgroundTaskIdentifier
    }
    
    private var tasks: [Task] = []
    private let workQueue = DispatchQueue(label: "com.hipwig.background.queue", qos: DispatchQoS.background)
    
    func startTask() -> BackgroundTaskIdentifier {
        let id = UUID().uuidString
        let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: id) {
            self.endTask(with: id)
        }
        
        let task = Task(id: id, taskIndentifier: backgroundTaskIdentifier)
        self.workQueue.async {
            self.tasks.append(task)
        }
        
        return id
    }
    
    func endTask(with identifier: BackgroundTaskIdentifier) {
        self.workQueue.sync {
            if let index = self.tasks.index(where: {$0.id == identifier }) {
                let task = self.tasks[index]
                UIApplication.shared.endBackgroundTask(task.taskIndentifier)
                
                self.tasks.remove(at: index)
            }
        }
    }
}



