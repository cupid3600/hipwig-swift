//
//  WebViewController.swift
//  Seat
//
//  Created by Vladyslav Shepitko on 12/28/17.
//  Copyright © 2017 Engineering Idea. All rights reserved.
//

import UIKit 
import SafariServices
import MessageUI
import WebKit

class WebViewController: UIViewController {

    //MARK: - Outlets -
    @IBOutlet weak var contentView: UIView!
    
    //MARK: - Properties -
    var url: URL?
    private lazy var wkView: WKWebView = { .init(frame: self.view.bounds, configuration: WKWebViewConfiguration()) }()
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prepareNavigationButtonForView()
        
        wkView.navigationDelegate = self
        self.contentView.place(wkView)
        
        DispatchQueue.main.async {
            if let url = self.url {
                do {
                    let content = try String(contentsOf: url)
                    self.wkView.loadHTMLString(content, baseURL: url)
                } catch {
                    
                }
            }
        }
    }
    
    private func prepareNavigationButtonForView() {
        let image = UIImage(named: "white_back_arrow_icon")
        let backButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(backSelected))
        navigationItem.leftBarButtonItem = backButton 
    }
    
    @objc private func backSelected() {
        navigationController?.dismiss(animated: true)
    }
}

//MARK: - Delegates -
//MARK: UIWebViewDelegate
extension WebViewController : WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        decisionHandler(WKNavigationActionPolicy.allow)
    }
}
