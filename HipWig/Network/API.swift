//
//  APIManager.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/17/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import AirNetwork

private var defaultSession: ANSession {
    let configuration = URLSessionConfiguration.background(withIdentifier: "com.hipwig.background_session")
    configuration.timeoutIntervalForResource = 60
    configuration.timeoutIntervalForRequest = 60
    
    return ANSession(configuration: configuration)
}

typealias Response = (data: Data?, response: HTTPURLResponse)
private typealias Async<T> = (_ request: ANRequest, _ success: @escaping (T) -> Void, _ failure: @escaping (Error) -> Void) -> Void

let API = APIManager()

class APIManager: ANManager {
    
    private var tasks: Set<APITask> = []
    private var isRefreshingToken = false
    private lazy var keychain: KeychainService = KeychainServiceImplementation.default
    private let attempts = 3
    private lazy var backgroundService: BackgroundTaskService = BackgroundTaskServiceImplementation()
    
    init() {
        super.init(session: defaultSession, domain: environment.baseURLString)
        self.debugLevel = .all
    }
    
    override func dataTask(with request: ANRequest) -> ANDataTask {
        return super.dataTask(with: request)
    }
    
    func dataTask(with request: ANRequest, useBackgroundTask: Bool = true, completion: @escaping ValueHandler<(data: Data, response: HTTPURLResponse)>) {

        let taskClosure: Async<Response> = { [weak self, weak backgroundService] request, success, failure in
            guard let `self` = self else { return }
            guard let backgroundService = backgroundService else { return }
            
            var request = request
            request.headerFields[ANAuthorization.Key] = self.keychain.accessToken
            
            var taskIdentifier: BackgroundTaskIdentifier?
            if useBackgroundTask {
                taskIdentifier = backgroundService.startTask()
            }
            
            let dataTask = self.dataTask(with: request)
            dataTask.completion { /*[weak dataTask, weak self]*/ result in
//                guard let `self` = self else { return }
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
//                self.printDescription(for: dataTask)
                
                if let taskId = taskIdentifier {
                    backgroundService.endTask(with: taskId)
                }
                
                switch result {
                case .success(let response):
                    success(response)
                case .error(let error):
                    failure(error)
                }
            }
        }
        
        self.retry(self.attempts, request: request, task: { taskClosure }, success: { response in
            if let data = response.data {
                let result = (data: data, response: response.response)
                completion(.success(result))
            } else {
                completion(.failure(RequestsManagerError.noData))
            }
        }) { error in
            completion(.failure(error))
        }
    }
    
    private func retry(_ numberOfTimes: Int,
                       request: ANRequest,
                       task: @escaping () -> Async<Response>,
                       success: @escaping (Response) -> Void,
                       failure: @escaping (Error) -> Void) {
        
        let networkTaskWrapper = APITask(request: request, numberOfTimes: numberOfTimes, task: task, success: success, failure: failure)
        self.tasks.insert(networkTaskWrapper)
        
        task()(request, { [weak self] responseData in
            guard let `self` = self else { return }
            
            if responseData.response.statusCode == 426 || responseData.response.statusCode == 401 {
                if !self.isRefreshingToken {
                    
                    self.isRefreshingToken = true
                    self.refreshToken { [weak self] error in
                        guard let `self` = self else {
                            return
                        }
                        
                        self.isRefreshingToken = false
                        
                        let tasks = self.tasks
                        self.tasks.removeAll()
                        
                        if let error = error {
                            logger.log(error)
                            analytics.log(.logout)
                            
                            tasks.forEach{ $0.failure(error) }
                            
//                            if case RequestsManagerError.invalidToken = error {
//                                MainStoryboard.showLogin()
//                            }
                        } else {
                            tasks.forEach { task in
                                self.retry(task.numberOfTimes, request: task.request, task: task.task, success: task.success, failure: task.failure)
                            }
                        }
                    }
                }
            } else {
                if let index = self.tasks.firstIndex(where: { $0.request == request }) {
                    self.tasks.remove(at: index)
                }

                success(responseData)
            }
            
        }, { [weak self] error in
            guard let `self` = self else { return }
            
            if error.isNetworkError && reachability.isNetworkReachable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if let index = self.tasks.firstIndex(where: { $0.request == request }) {
                        self.tasks.remove(at: index)
                    }
                    
                    if numberOfTimes > 1 {
                        self.retry(numberOfTimes - 1, request: request, task: task, success: success, failure: failure)
                    } else {
                        failure(error)
                    }
                }
            } else {
                if let index = self.tasks.firstIndex(where: { $0.request == request }) {
                    self.tasks.remove(at: index)
                }
                
                failure(error)
            }
        })
    }
    
    private func refreshToken(completion: @escaping ErrorHandler) {
        if self.keychain.accessToken.isEmpty || self.keychain.refreshToken.isEmpty {
            completion(RequestsManagerError.invalidToken)
        } else {
            var request = API.request(path: "/api/user/refresh", method: .POST)
            request.body = ANRequest.Body(contentType: .json, items: [
                "accessToken" : self.keychain.accessToken,
                "refreshToken" : self.keychain.refreshToken
            ])
        
            self.dataTask(with: request).completion { [weak self] result in
                guard let `self` = self else { return}
                
                switch result {
                case .success(let responseData):
                    
                    if let data = responseData.data {
                        let json = JSON(data: data)
                        
                        if json.isNull {
                            completion(RequestsManagerError.noData)
                        } else {
                            if json["status"].isNull {
                                self.keychain.accessToken = json["accessToken"].stringValue
                                self.keychain.refreshToken = json["refreshToken"].stringValue
                                
                                if self.keychain.accessToken.isEmpty && self.keychain.refreshToken.isEmpty {
                                    completion(RequestsManagerError.invalidToken)
                                } else {
                                    completion(nil)
                                }
                            } else {
                                completion(RequestsManagerError.invalidToken)
                            }
                        }
                    } else {
                        completion(RequestsManagerError.noData)
                    }
                case .error(let error):
                    completion(error)
                }
            }
        }
    }
    
    private func printDescription(for task: ANTask?) {
        print("===> RESPONSE(\(task?.request?.url?.absoluteString ?? "-"))")
        if let response = task?.httpResponse {
            print("\(response.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))")
            print("\(response.allHeaderFields.map { "\($0.key): \($0.value)\n" }.joined())")
        }
        
        if let data = (task as? ANDataTask)?.data {
            let jsonString = String(data: data, encoding: .utf8)
            print(jsonString ?? "{ }")
        }
        
        print("RESPONSE <===")
    }
} 

private struct APITask : Hashable, Equatable {
    
    var request: ANRequest
    var numberOfTimes: Int
    var task: () -> Async<Response>
    var success: (Response) -> Void
    var failure: (Error) -> Void
    
    static func == (lhs: APITask, rhs: APITask) -> Bool {
        return lhs.request == rhs.request
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(request)
    }
}
