//
//  RequestsManager.swift
//  HipWig
//
//  Created by Alexey on 1/15/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import Alamofire 
import AlamofireNetworkActivityIndicator
import Reachability
import SVProgressHUD
import FBSDKCoreKit
import MulticastDelegateSwift
import AirNetwork

enum Result<T> {
    case success(T)
    case failure(Error)
}

typealias VoidHandler = () -> Void
typealias ValueHandler<T> = (Result<T>) -> Void
typealias ObjectHandler<T> = (T) -> Void
typealias ExpertStatisticsHandler = (Float, Float, Error?) -> Void
typealias ErrorHandler = (Error?) -> Void


enum RequestsManagerError : Int, Error {
    case noData
    case invalidToken
    case userAlreadyExist = 400
    case compressImage
    case invalidJSON
    
    var localizedDescription: String {
        switch self {
        case .noData:
            return "Response data not found"
        case .userAlreadyExist:
            return "User already exists"
        case .compressImage:
            return "Compress image error"
        case .invalidJSON:
            return "Receive invalid json"
        case .invalidToken:
            return "Access token is invalid. Try to re-login."
        }
    }
}

class RequestsManager: RequestRetrier, RequestAdapter {
    
    static public var manager = RequestsManager(baseURL: environment.baseURL)
    private lazy var backgroundService: BackgroundTaskService = BackgroundTaskServiceImplementation()
    private let keychain: KeychainService = KeychainServiceImplementation.default
    
    private let baseURL: URL

    private let lock = NSLock()
    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []
    
    public var sessionManager: Alamofire.SessionManager!
    
    private lazy var uploadSessionManager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.hipwig.uploadvideo")
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 60 * 10
        configuration.timeoutIntervalForResource = 60 * 10
        
        let manager = SessionManager(configuration: configuration)
        manager.retrier = self
        manager.adapter = self
        
        return manager
    }()
    
    public func loginWithFacebook(token: String, completion: @escaping ErrorHandler) {
//        let url = URL(string: "/api/user/auth/facebook", relativeTo: self.baseURL)!
//
//        let request = Alamofire.request(url, method: .post, parameters: ["accessToken" : token])
//        request.responseJSON { response in
//            switch response.result {
//            case .success:
//
//                guard let responseData = response.data else {
//                    completion(RequestsManagerError.noData)
//                    return
//                }
//
//                do {
//                    let response = try JSONDecoder().decode(LoginResponse.self, from: responseData)
//
//                    self.keychain.accessToken = response.accessToken
//                    self.keychain.refreshToken = response.refreshToken
//
//                    AccountManager.manager.setUser(user: response.profile)
//
//                    completion(nil)
//                } catch {
//                    completion(error)
//                }
//
//            case .failure(let error):
//                completion(error)
//            }
//        }
        
        var request = API.request(path: "/api/user/auth/facebook", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: ["accessToken" : token])
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let dataResponse):
                do {
                    let response = try JSONDecoder().decode(LoginResponse.self, from: dataResponse.data)
                    
                    self.keychain.accessToken = response.accessToken
                    self.keychain.refreshToken = response.refreshToken
                    
                    AccountManager.manager.setUser(user: response.profile)
                    
                    completion(nil)
                } catch {
                    completion(error)
                }
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    typealias LanguageJSON = String
    public func fetchLanguage(completion: @escaping ValueHandler<LanguageJSON> ) {
//        let url = URL(string: "/assets/localization/lang-en.json", relativeTo: self.baseURL)!
//
//        let request = Alamofire.request(url)
//        request.responseString { response in
//            switch response.result {
//            case .success:
//                guard let responseData = response.data else {
//                    completion(.failure( RequestsManagerError.noData))
//                    return
//                }
//
//                if let json = String(data: responseData, encoding: .utf8) {
//                    completion(.success(json))
//                } else {
//                    completion(.failure(RequestsManagerError.noData))
//                }
//
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
        
        let request = API.request(path: "/assets/localization/lang-en.json", method: .GET)
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let response):
                if let json = String(data: response.data, encoding: .utf8) {
                    completion(.success(json))
                } else {
                    completion(.failure(RequestsManagerError.noData))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func fetchProductInfoList(completion: @escaping ValueHandler<[Product]>) {
//        let url = URL(string: "/api/price/", relativeTo: self.baseURL)!
//
//        let headers: HTTPHeaders = [
//            "Authorization": self.keychain.accessToken,
//            "Accept": "application/json"
//        ]
//        let params: [String : Any] = [:]
        
        var request = API.request(path: "/api/price/", method: .GET)
//        request.body = ANRequest.Body(contentType: .json, items: params)
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let response):
                do {
                    let subscriptions = try JSONDecoder().decode([Product].self, from: response.data)
                    completion(.success(subscriptions))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        //FIXME: will be used later
//        let params: [String : Any] = [:]

//        self.request(url, method: .get, parameters: params, headers: headers) { response in
//            switch response.result {
//            case .success:
//                guard let responseData = response.data else {
//                    completion(.failure( RequestsManagerError.noData))
//                    return
//                }
//
//                do {
//                    let subscriptions = try JSONDecoder().decode([Product].self, from: responseData)
//                    completion(.success(subscriptions))
//                } catch let error {
//                    completion(.failure(error))
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
    }

    public func loginWithGoogle(token: String, completion: @escaping ErrorHandler) {
//        let url = URL(string: "/api/user/auth/google", relativeTo: self.baseURL)!
//
//        let request = Alamofire.request(url, method: .post, parameters: ["accessToken" : token])
//        request.responseJSON { response in
//            switch response.result {
//            case .success:
//
//                guard let responseData = response.data else {
//                    completion(RequestsManagerError.noData)
//                    return
//                }
//
//                do {
//                    let response = try JSONDecoder().decode(LoginResponse.self, from: responseData)
//
//                    self.keychain.accessToken = response.accessToken
//                    self.keychain.refreshToken = response.refreshToken
//
//                    AccountManager.manager.setUser(user: response.profile)
//
//                    completion(nil)
//                } catch {
//                    completion(error)
//                }
//
//            case .failure(let error):
//                completion(error)
//            }
//        }
        
        var request = API.request(path: "/api/user/auth/google", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: ["accessToken" : token])
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let dataResponse):
                do {
                    let response = try JSONDecoder().decode(LoginResponse.self, from: dataResponse.data)
                    
                    self.keychain.accessToken = response.accessToken
                    self.keychain.refreshToken = response.refreshToken
                    
                    AccountManager.manager.setUser(user: response.profile)
                    
                    completion(nil)
                } catch {
                    completion(error)
                }
            case .failure(let error):
                completion(error)
            }
        }
    }
    
//    func fetchInstagramPhotos() {
//        
//        if let request = FBSDKGraphRequest(graphPath: "me", parameters: [:], httpMethod: "GET") {
//            
//            let connection = FBSDKGraphRequestConnection()
//            connection.add(request) { connection, data, error in
//                
//            }
//            
//            connection.start()
//        }
//    }

//    public func loginWithInstagram(token: String, completion: @escaping (_ result: DataResponse<Any>) -> Void) {
//        let url = URL(string: "/api/user/auth/instagram", relativeTo: self.baseURL)!
//
//        let request = Alamofire.request(url, method: .post, parameters: ["accessToken" : token])
//        request.responseJSON { response in
//            switch response.result {
//            case .success:
//
//                guard let responseData = response.data else {
//                    print("didn't get any data from APIManager")
//                    return
//                }
//                do {
//                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: responseData)
//
//                    self.accessToken = loginResponse.accessToken
//                    self.refreshToken = loginResponse.refreshToken
//                    AccountManager.manager.setUser(user: loginResponse.profile)
//                    AccountManager.manager.save(accessToken: self.accessToken, refreshToken: self.refreshToken)
//                } catch {
//                    print(error)
//                }
//
//            case .failure(let error):
//                print(error)
//            }
//
//            completion(response)
//        }
//    }
//
//    public func connectInstagram(token: String, completion: @escaping ErrorHandler) {
//        let url = URL(string: "/api/user/instagram", relativeTo: self.baseURL)!
//
//        self.request(url, method: .post, parameters: ["accessToken" : token]) { response in
//            switch response.result {
//            case .success:
//                completion(nil)
//
//            case .failure(let error):
//                if let response = response.response {
//                    let requestError = RequestsManagerError(rawValue: response.statusCode) ?? error
//                    completion(requestError)
//                } else {
//                    completion(error)
//                }
//            }
//        }
//    }

//    public func disconnectInstagram(completion: @escaping ErrorHandler) -> DataRequest {
//        let url = URL(string: "/api/user/instagram", relativeTo: self.baseURL)!
//
//        return self.request(url, method: .delete, parameters: nil) { response in
//            switch response.result {
//            case .success:
//                completion(nil)
//
//            case .failure(let error):
//                completion(error)
//            }
//        }
//    }

    func updateUser(with userDTO: InternalExpert, for userId: String, completion: @escaping ValueHandler<User>) {
//        let url = URL(string: "/api/expert/\(userId)", relativeTo: self.baseURL)!
//
//        let headers: HTTPHeaders = [
//            "Authorization": self.keychain.accessToken,
//            "Accept": "application/json"
//        ]
//
        var params: [String : Any] = [:]
        if let payPalEmail = userDTO.payPalEmail {
            params["paypalAccount"] = payPalEmail
        }
        
        params["skills"] = userDTO.directions.map{ $0.id }
        params["location"] = userDTO.location ?? ""
        if let image = userDTO.userImage {
            params["profileImage"] = image
        }
        
        params["publicProfile"] = userDTO.publicProfile
        params["available"] = userDTO.available

        var request = API.request(path: "/api/expert/\(userId)", method: .PUT)
        request.body = ANRequest.Body(contentType: .json, items: params)
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let response):
                do {
                    let expert = try JSONDecoder().decode(User.self, from: response.data)
                    AccountManager.manager.setUser(user: expert)
                    
                    completion(.success(expert))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
//        return self.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers) { response in
//            switch response.result {
//            case .success:
//                guard let responseData = response.data else {
//                    completion(.failure( RequestsManagerError.noData))
//                    return
//                }
//
//                do {
//                    let expert = try JSONDecoder().decode(User.self, from: responseData)
//                    AccountManager.manager.setUser(user: expert)
//
//                    completion(.success(expert))
//                } catch let error {
//                    completion(.failure(error))
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
    }

    func uploadVideo(with videoURL: URL, completion: @escaping ValueHandler<User>) {
        let url = URL(string: "/api/expert/upload", relativeTo: self.baseURL)!

        let headers: HTTPHeaders = [
            "Authorization": self.keychain.accessToken,
            "Content-type": "multipart/form-data"
        ]
        
        let id = backgroundService.startTask()
        self.uploadSessionManager.upload(multipartFormData: { multipartForm in
            multipartForm.append(videoURL, withName: "profileVideo")
        }, to: url,
           method: .post,
           headers: headers) { result in
            switch result {
            case .success(let upload, _ , _):
                upload.uploadProgress { _ in }
                
                upload.responseJSON { response in
                    guard let responseData = response.data else {
                        completion(.failure( RequestsManagerError.noData))
                        return
                    }
                    
                    do {
                        let expert = try JSONDecoder().decode(User.self, from: responseData)
                        AccountManager.manager.setUser(user: expert)
                        
                        completion(.success(expert))
                        AppDelegate.shared.sendLocalPushNotificationOnce(content: LocalNotificationContent.VideoUploaded.notificationContent)
                    } catch let error {
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
            
            self.backgroundService.endTask(with: id) 
        }
    }
    
    public func getExpertsList(filter: ExpertsFilter, pagination: Pagination, completion: @escaping ValueHandler<ExpertListResponse>) {

//        let url = URL(string: "/api/expert/", relativeTo: self.baseURL)!
        var params: [String : Any] = [:]
        params["gender"] = filter.sex?.value ?? ""
        params["workType"] = filter.purpose?.value ?? ""
//        params["location"] = location
        params["offset"] = NSNumber(integerLiteral: pagination.offset)
        params["limit"] = NSNumber(integerLiteral: pagination.limit)

//        let headers: HTTPHeaders = [
//            "Authorization": self.keychain.accessToken,
//            "Accept": "application/json"
//        ]

//        _ = self.request(url, parameters: params, headers: headers) { response in
//            switch response.result {
//            case .success:
//                guard let responseData = response.data else {
//                    completion(.failure(RequestsManagerError.noData))
//                    return
//                }
//
//                do {
//                    let expertsResponse = try JSONDecoder().decode(ExpertListResponse.self, from: responseData)
//                    completion(.success(expertsResponse))
//                } catch let error {
//                    completion(.failure(error))
//                }
//
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }

        var request = API.request(path: "/api/expert/", method: .GET)
        request.headerFields = ["Accept": "application/json"]
        request.queryItems = params

        API.dataTask(with: request) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let dataResponse):
                do {
                    let expertsResponse = try JSONDecoder().decode(ExpertListResponse.self, from: dataResponse.data)
                    completion(.success(expertsResponse))
                } catch let error {
                    completion(.failure(error))
                }
            }
        }
    }
    
    public func sendSpendedTime(timeInterval time: TimeInterval, expert ID: String, completion: @escaping ErrorHandler) {

        var params: [String : Any] = [:]
        params["time"] = time
        params["expertId"] = ID 
        
        var request = API.request(path: "/api/user/time", method: .PUT)
        request.body = ANRequest.Body(contentType: .json, items: params)
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    public func loadDialog(id: String, completion: @escaping ValueHandler<Conversation?>) {
        completion(.success(nil))
    }
        
    public func createChat(userID: String?, expertID: String?, completion: @escaping ValueHandler<String>) {
        var params: [String : Any] = [:]
        
        params["userId"] = userID
        params["expertId"] = expertID

        var request = API.request(path: "/api/chat/", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: params)
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let responseData):
                let json = JSON(data: responseData.data)
                if json.isNull {
                    completion(.failure(RequestsManagerError.invalidJSON))
                } else {
                    let id = json["id"].stringValue
                    completion(.success(id))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getChatHistory(_ id: String, pagination: Pagination, completion: @escaping ValueHandler<ChatMessagesListResponse>) {
        var params: [String : Any] = [:]
        params["limit"] = pagination.limit
        params["offset"] = pagination.offset
        
        var request = API.request(path: "/api/chat/" + id, method: .GET)
        request.queryItems = params
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let responseData):
                do {
                    let response = try JSONDecoder().decode(ChatMessagesListResponse.self, from: responseData.data)
                    completion(.success(response))
                } catch let error  {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getChatHistory(_ id: String, date: Date, completion: @escaping ValueHandler<LastChatMessagesListResponse>) {
        var request = API.request(path: "/api/message/chat/", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: [
            "chatId": id,
            "messageDate": date.timeIntervalSince1970 * 1000
        ])
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let responseData):
                do {
                    let response = try JSONDecoder().decode(LastChatMessagesListResponse.self, from: responseData.data)
                    completion(.success(response))
                } catch let error  {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getChatHistory(_ id: String, lastMesage message: String, completion: @escaping ValueHandler<LastChatMessagesListResponse>) {
        var request = API.request(path: "/api/message/user/", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: [
            "messageId": message,
            "userId": id
        ])
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let responseData):
                do {
                    let response = try JSONDecoder().decode(LastChatMessagesListResponse.self, from: responseData.data)
                    completion(.success(response))
                } catch let error  {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func getChatHistory(chatID id: String, limit: Int, offset: Int, completion: @escaping ValueHandler<ChatMessagesListResponse>) {
        var params: [String : Any] = [:]
        params["limit"] = limit
        params["offset"] = offset

        var request = API.request(path: "/api/chat/" + id, method: .GET)
        request.queryItems = params
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let responseData):
                do {
                    let response = try JSONDecoder().decode(ChatMessagesListResponse.self, from: responseData.data)
                    completion(.success(response))
                } catch let error  {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getUserChats(pagination: Pagination, completion: @escaping ValueHandler<ConversationsListResponse>) {
        var params: [String : Any] = [:]
        params["limit"] = pagination.limit
        params["offset"] = pagination.offset
        
        var request = API.request(path: "/api/chat/", method: .GET)
        request.queryItems = params
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let responseData):
                do {
                    let response = try JSONDecoder().decode(ConversationsListResponse.self, from: responseData.data)
                    completion(.success(response))
                } catch let error  {
                    completion(.failure(error))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func updatePushToken(pushToken token: String, deviceToken: String, type: TokenType, completion: @escaping ErrorHandler) {
        var request = API.request(path: "/api/user/push", method: .POST)
        request.headerFields = ["Accept": "application/json"]
        request.body = ANRequest.Body(contentType: .json, items: [
            "pushToken" : token,
            "deviceId": deviceToken,
            "pushType": type.rawValue
        ])
        
        API.dataTask(with: request) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    public func deleteChat(chatID id: String, completion: @escaping ErrorHandler) {
//        let url = URL(string: "/api/chat/" + chatID, relativeTo: self.baseURL)!
//
//        let headers: HTTPHeaders = [
//            "Authorization": self.keychain.accessToken,
//            "Accept": "application/json"
//        ]
//
//        return self.request(url, method: .delete, headers: headers) { response in
//            switch response.result {
//            case .success:
//                if response.data == nil {
//                    completion(RequestsManagerError.noData)
//                } else {
//                    completion(nil)
//                }
//            case .failure(let error):
//                completion(error)
//            }
//        }
        
        var request = API.request(path: "/api/chat/" + id, method: .DELETE)
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    public func logout(_ completion: @escaping ErrorHandler) {
        
        var request = API.request(path: "/api/user/logout", method: .POST)
        request.headerFields = ["Accept": "application/json"]

        API.dataTask(with: request) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
        
//        let url = URL(string: "/api/user/logout", relativeTo: self.baseURL)!
//
//        let headers: HTTPHeaders = [
//            "Authorization": self.keychain.accessToken,
//            "Accept": "application/json"
//        ]
//
//        self.request(url, method: .post, headers: headers) { response in
//            switch response.result {
//            case .success:
//                if response.data == nil {
//                    completion(RequestsManagerError.noData)
//                } else {
//                    completion(nil)
//                }
//            case .failure(let error):
//                completion(error)
//            }
//        }
    }

    public func block(userID id: String, completion: @escaping ErrorHandler) {
        var request = API.request(path: "/api/user/" + id + "/block", method: .POST)
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    public func unblock(userID id: String, completion: @escaping ErrorHandler) {
        var request = API.request(path: "/api/user/" + id + "/block", method: .DELETE)
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    public func refreshToken(accessToken: String, refreshToken: String, completion: @escaping (_ result: DataResponse<Any>) -> Void) {

        let url = URL(string: "/api/user/refresh", relativeTo: self.baseURL)!

        let params = [
            "accessToken" : accessToken,
            "refreshToken" : refreshToken
        ]

        let request = Alamofire.request(url, method: .post, parameters: params)
        request.responseJSON(completionHandler: completion) 
    }

    typealias CreateCallData = (session: String, token: String)
    public func createCall(userID: String?, expertID: String?, completion: @escaping ValueHandler<CreateCallData>) {
        var params: [String: String] = [:]
        if let id = expertID {
            params = ["expertId" : id]
        }
        if let id = userID {
            params = ["userId" : id]
        }

        var request = API.request(path: "/api/call/", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: params)
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let responseData):
                let json = JSON(data: responseData.data)
                
                if json.isNull {
                    completion(.failure(RequestsManagerError.invalidJSON))
                } else {
                    if let session = json["sessionId"].string, let token = json["tokenId"].string {
                        completion(.success((session, token)))
                    } else {
                        completion(.failure(RequestsManagerError.noData))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func declineCall(receiver id: String, completion: @escaping ErrorHandler) {
        var request = API.request(path: "/api/call/decline", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: ["partnerId" : id])
        
        API.dataTask(with: request) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    public func acceptCall(receiver id: String, completion: @escaping ErrorHandler) {
        var request = API.request(path: "/api/call/accept", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: ["partnerId" : id])
        
        API.dataTask(with: request) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    public func resumeCall(receiver id: String, completion: ErrorHandler? = nil) {
        var request = API.request(path: "/api/call/unpause", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: ["expertId" : id])
        
        API.dataTask(with: request) { result in
            var responseError: Error? = nil
            switch result {
            case .success:
                break
            case .failure(let error):
                responseError = error
            }
            
            completion?(responseError)
        }
    }

    public func pauseCall(receiver id: String, completion: ErrorHandler? = nil) {
        var request = API.request(path: "/api/call/pause", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: ["expertId" : id])
        
        API.dataTask(with: request) { result in
            var responseError: Error? = nil
            switch result {
            case .success:
                break
            case .failure(let error):
                responseError = error
            }
            
            completion?(responseError)
        }
    }
    public func finishCall(opponentID: String, completion: @escaping ErrorHandler) {
        var request = API.request(path: "/api/call/end", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: ["partnerId" : opponentID ])
        
        API.dataTask(with: request, useBackgroundTask: false) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    public func fetchUser(id: String, completion: @escaping ValueHandler<User>) {
        let request = API.request(path: "/api/user/" + id, method: .GET)
        API.dataTask(with: request) { result in
            switch result {
            case .success(let responseData):
                do {
                    let user = try JSONDecoder().decode(User.self, from: responseData.data)
                    completion(.success(user))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func fetchFeatureFlags(_ pagination: Pagination, categoryId: String? = nil, completion: @escaping ValueHandler<FeatureFlagListResponse>) {
        var params: [String: Any] = [:]
        params["offset"] = NSNumber(integerLiteral: pagination.offset)
        params["limit"] = NSNumber(integerLiteral: pagination.limit)
        if let categoryId = categoryId {
            params["page"] = categoryId
        }
        
        var request = API.request(path: "/api/feature/", method: .GET)
        request.queryItems = params
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let response):
                do {
                    let featureFlagResponse = try JSONDecoder().decode(FeatureFlagListResponse.self, from: response.data)
                    completion(.success(featureFlagResponse))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func fetchStaticResources(_ pagination: Pagination, categoryId: String? = nil, completion: @escaping ValueHandler<StaticResourceResponse>) {
        var params: [String: Any] = [:]
        params["offset"] = NSNumber(integerLiteral: pagination.offset)
        params["limit"] = NSNumber(integerLiteral: pagination.limit)

        if let categoryId = categoryId {
            params["page"] = categoryId
        }

        var request = API.request(path: "/api/resource/", method: .GET)
        request.queryItems = params
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try JSONDecoder().decode(StaticResourceResponse.self, from: response.data)
                    completion(.success(response))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func fetchExpertSkillList(_ pagination: Pagination, completion: @escaping ValueHandler<ExpertSkillListResponse>) {

        var params: [String: Any] = [:]
        params["offset"] = NSNumber(integerLiteral: pagination.offset)
        params["limit"] = NSNumber(integerLiteral: pagination.limit)

        var request = API.request(path: "/api/skill/", method: .GET)
        request.queryItems = params
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let response):
                do {
                    let skillsResponse = try JSONDecoder().decode(ExpertSkillListResponse.self, from: response.data)
                    completion(.success(skillsResponse))
                } catch let error {
                    completion(.failure(error))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func uploadReceipt(recipe: String, completion: @escaping ErrorHandler) {

        var request = API.request(path: "/api/user/receipt", method: .POST)
        request.body = ANRequest.Body(contentType: .json, items: ["receipt": recipe])

        API.dataTask(with: request) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    public func getExpertStatistics(completion: @escaping ExpertStatisticsHandler) {
        let request = API.request(path: "/api/user/statistic", method: .GET)
        API.dataTask(with: request) { result in
            switch result {
            case .success(let response):
                let json = JSON(data: response.data)
                if json.isNull {
                    completion(0.0, 0.0, nil)
                } else {
                    let month = json["monthEarn"].floatValue
                    let total = json["totalEarn"].floatValue
                    
                    completion(month, total, nil)
                }
            case .failure(let error):
                completion(0.0, 0.0, error)
            }
        }
    }
    
    public func publishExpertProfile(completion: @escaping ErrorHandler) {
        let request = API.request(path: "/api/expert/publish", method: .POST)
        API.dataTask(with: request) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    public func getAvailableMinutes(for user: String, completion: @escaping ValueHandler<Bool>) {
        var request = API.request(path:"/api/user/time/\(user)", method: .GET)
        request.headerFields = ["Accept": "application/json"]
        
        API.dataTask(with: request) { result in
            switch result {
            case .success(let responseData):
                do {
                    let user = try JSONDecoder().decode(User.self, from: responseData.data)
                    
                    completion(.success(user.availableTime > 0))
                } catch {
                    completion(.success(false))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func uploadUserPhoto(image: UIImage, completion: @escaping ValueHandler<User>) {
        let url = URL(string: "/api/user/upload", relativeTo: self.baseURL)!

        guard let data = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(RequestsManagerError.noData))
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": self.keychain.accessToken,
            "Content-type": "multipart/form-data"
        ]
 
        let id = backgroundService.startTask()
        self.uploadSessionManager.upload(multipartFormData: { multipartForm in
            multipartForm.append(data, withName: "profileImage",fileName: "file.jpg", mimeType: "image/jpg")
        }, to: url,
           method: .post,
           headers: headers) { result in
            switch result {
            case .success(let upload, _ , _):
                upload.uploadProgress { _ in }

                upload.responseJSON { response in
                    self.backgroundService.endTask(with: id)
                    
                    guard let responseData = response.data else {
                        completion(.failure(RequestsManagerError.noData))
                        return
                    }

                    do {
                        let expert = try JSONDecoder().decode(User.self, from: responseData)
                        AccountManager.manager.setUser(user: expert)
                        completion(.success(expert))
                    } catch let error {
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                self.backgroundService.endTask(with: id)
                
                completion(.failure(error))
            }
        }
    }

    public func unarchiveUserData() {
        AccountManager.manager.unarchiveUser()
    }

    private init(baseURL: URL) {
        self.baseURL = baseURL
        
        NetworkActivityIndicatorManager.shared.isEnabled = true

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 30 // seconds
        configuration.timeoutIntervalForRequest = 30 // s
        
        self.sessionManager = Alamofire.SessionManager(configuration: configuration)

        self.sessionManager.retrier = self
        self.sessionManager.adapter = self
    }

    // MARK: - RequestRetrier
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        lock.lock() ; defer { lock.unlock() }

        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 426 || response.statusCode == 401 else {
            completion(false, 0.0)
            return
        }
        
        requestsToRetry.append(completion)
        if !isRefreshing {

            isRefreshing = true
            self.refreshToken(accessToken: self.keychain.accessToken, refreshToken: self.keychain.refreshToken) { [weak self] response in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.lock.lock();

                defer {
                    strongSelf.lock.unlock()
                }

                guard let data = response.result.value as? [String : String] else {
                    AccountManager.manager.logout{ error in
                        if let error = error {
                            SVProgressHUD.showError(withStatus: error.localizedDescription)
                        }
                        
                        MainStoryboard.showLogin()
                        
                        completion(false, 0.0)
                    }
                    
                    return
                }
                
                if let _ = data["status"] {
                    AccountManager.manager.logout{ error in
                        if let error = error {
                            SVProgressHUD.showError(withStatus: error.localizedDescription)
                        }
                        
                        MainStoryboard.showLogin()
                        
                        completion(false, 0.0)
                    }
                    
                } else {
                    strongSelf.keychain.accessToken = data["accessToken"] ?? ""
                    strongSelf.keychain.refreshToken = data["refreshToken"] ?? ""

                    strongSelf.requestsToRetry.forEach { $0(true, 0.1) }
                    strongSelf.requestsToRetry.removeAll()

                    strongSelf.isRefreshing = false

                    completion(true, 0.0)
                }
            }
        }
    }

    // MARK: - RequestAdapter
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest

        if let urlString = urlRequest.url?.absoluteString, urlString.hasPrefix(self.baseURL.absoluteString) {
            urlRequest.setValue(self.keychain.accessToken, forHTTPHeaderField: "Authorization")
        }

        return urlRequest
    }
}
