//
//  InstagramLoginViewController.swift
//  SwiftInstagram
//
//  Created by Ander Goig on 8/9/17.
//  Copyright © 2017 Ander Goig. All rights reserved.
//

import UIKit
import WebKit

class InstagramLoginViewController: UIViewController {

    // MARK: Types

    typealias SuccessHandler = (_ accesToken: String) -> Void
    typealias FailureHandler = (_ error: InstagramError) -> Void

    // MARK: Properties

    private var authURL: URL
    private var success: SuccessHandler?
    private var failure: FailureHandler?

    private var progressView: UIProgressView!
    private var webViewObservation: NSKeyValueObservation!

    // MARK: Initializers

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(authURL: URL, success: SuccessHandler?, failure: FailureHandler?) {
        self.authURL = authURL
        self.success = success
        self.failure = failure
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.setHidesBackButton(true, animated:true);
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelDidSelect))
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        // Initializes progress view
        setupProgressView()

        // Initializes web view
        let webView = makeWebView()

        // Starts authorization
        webView.load(URLRequest(url: authURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
    }
    
    @objc private func cancelDidSelect() {
        failure?(.cancel)
    }

    deinit {
        progressView.removeFromSuperview()
        webViewObservation.invalidate()
    }

    // MARK: Setup

    private func setupProgressView() {
        let navBar = navigationController!.navigationBar

        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progress = 0.0
        progressView.tintColor = UIColor(red: 0.88, green: 0.19, blue: 0.42, alpha: 1.0)
        progressView.translatesAutoresizingMaskIntoConstraints = false

        navBar.addSubview(progressView)

        let bottomConstraint = navBar.bottomAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 1)
        let leadingConstraint = navBar.leadingAnchor.constraint(equalTo: progressView.leadingAnchor)
        let trailingConstraint = navBar.trailingAnchor.constraint(equalTo: progressView.trailingAnchor)

        NSLayoutConstraint.activate([bottomConstraint, leadingConstraint, trailingConstraint])
    }

    private func makeWebView() -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: view.frame, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        webViewObservation = webView.observe(\.estimatedProgress) { [weak self] webView, observer in
            guard let `self` = self else { return }
            self.progressViewChangeHandler(webView: webView, change: observer)
        }
        
        view.addSubview(webView)

        var topAnchor = view.topAnchor
        let bottomAnchor = view.bottomAnchor

        if #available(iOS 11.0, *) {
            topAnchor = view.safeAreaLayoutGuide.topAnchor
//            bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        }

        let topConstraint = webView.topAnchor.constraint(equalTo: topAnchor)
        let bottomConstraint = webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let leadingAnchor = webView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailingAnchor = webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)

        NSLayoutConstraint.activate([topConstraint, bottomConstraint, leadingAnchor, trailingAnchor])

        return webView
    }

    private func progressViewChangeHandler<Value>(webView: WKWebView, change: NSKeyValueObservedChange<Value>) {
        progressView.alpha = 1.0
        progressView.setProgress(Float(webView.estimatedProgress), animated: true)

        if webView.estimatedProgress >= 1.0 {
            UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: {
                self.progressView.alpha = 0.0
            }, completion: { _ in
                self.progressView.progress = 0
            })
        }
    }

}

// MARK: - WKNavigationDelegate

extension InstagramLoginViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationItem.title = webView.title
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        let urlString = navigationAction.request.url!.absoluteString

        guard let range = urlString.range(of: "#access_token=") else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)

        DispatchQueue.main.async { [weak self] in
            self?.success?(String(urlString[range.upperBound...]))
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

        guard let httpResponse = navigationResponse.response as? HTTPURLResponse else {
            decisionHandler(.allow)
            return
        }

        switch httpResponse.statusCode {
        case 400:
            decisionHandler(.cancel)
            DispatchQueue.main.async { [weak self] in
                self?.failure?(InstagramError.badRequest)
            }
        default:
            decisionHandler(.allow)
        }
    }
}
