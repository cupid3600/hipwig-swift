//
//  Localization.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/20/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import Localize

class Localization: NSObject {
    
    private let localizeKey = "lang"
    private let defaultLanguage = "en"
    private let localize = Localize.shared
    private let requestsManager = RequestsManager.manager
    private let fileManager = FileManager.default
    
    func load(completion: @escaping VoidHandler) {
        
        let provider = DocumentsLocalizeJson()
        self.localize.update(provider: .custom(provider: provider))
        self.localize.update(fileName: self.localizeKey)
        self.localize.update(defaultLanguage: self.defaultLanguage)
        
        if let languageFolderURL = URL.createFolderIfNotExists(folderName: languagesFolderName) {
            self.copyLanguageFromBundle(to: languageFolderURL)
            self.updateLocalization()

            self.requestsManager.fetchLanguage { result in
                if let languageFolderURL = URL.createFolderIfNotExists(folderName: languagesFolderName) {
                    switch result {
                    case .success(let json):
                        let url = languageFolderURL.appendingPathComponent("\(self.localizeKey)-" + self.defaultLanguage.localizationFileName)
                        self.createLanguageIfNotExist(with: json, at: url)
                    case .failure(let error):
                        logger.log(error)
                        self.copyLanguageFromBundle(to: languageFolderURL)
                    }
                }
            
                self.updateLocalization()
                completion()
            }
        } else {
            completion()
        }
    }
    
    private func updateLocalization() {
        self.localize.update(language: "en")
    }
    
    private func copyLanguageFromBundle(to url: URL) {
        let paths = self.languagesMappedToPath()
        
        for (name, path) in paths {
            do {
                let languageData = try Data(contentsOf: URL(fileURLWithPath: path))
                var url = url
                url.appendPathComponent(name)
            
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.removeItem(atPath: url.path)
                }
                
                try languageData.write(to: url)
            } catch let error {
                print("can't save file: \(error)")
            }
        }
    }
    
    private func createLanguageIfNotExist(with content: String, at url: URL) {
        if let languageData = content.data(using: .utf8) {
            
            do {
                if self.fileManager.fileExists(atPath: url.path) {
                    try self.fileManager.removeItem(atPath: url.path)
                }
                
                try languageData.write(to: url)
                
            } catch let error {
                logger.log(error)
            }
        }
    }
    
    private func languagesMappedToPath() -> [String: String] {
        var paths: [String: String] = [:]
        for localeId in NSLocale.availableLocaleIdentifiers {
            let name = "\(self.localizeKey)-\(localeId)"
            let path = Bundle.main.path(forResource: name, ofType: "json")
            if let path = path {
                paths[name.localizationFileName] = path
            }
        }
        
        return paths
    }
}

private extension String {
    
    var localizationFileName: String {
        return self + "." + "json"
    }
}


extension NotificationCenter {
    
    class func addUpdateLocalizationObserver(_ completion: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: localizeChangeNotification), object: nil, queue: .main) { _ in
            completion()
        }
    }
}
