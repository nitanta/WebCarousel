//
//  WebViewStateModel.swift
//  WebCarousel
//
//  Created by Nitanta Adhikari on 18/08/2023.
//

import SwiftUI
import WebKit

class WebViewStateModel: ObservableObject {
    @Published var pageTitle: String = "Web View"
    @Published var loading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var goBack: Bool = false
}

struct WebView: View {
    enum NavigationAction {
        case decidePolicy(WKNavigationAction, (WKNavigationActionPolicy) -> Void)
        case didRecieveAuthChallange(URLAuthenticationChallenge, (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
        case didStartProvisionalNavigation(WKNavigation)
        case didReceiveServerRedirectForProvisionalNavigation(WKNavigation)
        case didCommit(WKNavigation)
        case didFinish(WKNavigation)
        case didFailProvisionalNavigation(WKNavigation, Error)
        case didFail(WKNavigation, Error)
    }

    @ObservedObject var webViewStateModel: WebViewStateModel

    // swiftlint:disable weak_delegate
    private var actionDelegate: ((_ navigationAction: WebView.NavigationAction) -> Void)?

    let request: URLRequest?
    let htmlString: String?
    let baseUrl: URL?

    var body: some View {

        WebViewWrapper(webViewStateModel: webViewStateModel,
                       action: actionDelegate,
                       request: request,
                       htmlString: htmlString,
                       baseUrl: baseUrl)
    }
    /*
     if passed onNavigationAction it is mandatory to complete URLAuthenticationChallenge and decidePolicyFor callbacks
     */
    init(request: URLRequest, webViewStateModel: WebViewStateModel, onNavigationAction: ((_ navigationAction: WebView.NavigationAction) -> Void)?) {
        self.request = request
        self.webViewStateModel = webViewStateModel
        self.actionDelegate = onNavigationAction
        self.baseUrl = nil
        self.htmlString = nil
    }

    init(url: URL, webViewStateModel: WebViewStateModel, onNavigationAction: ((_ navigationAction: WebView.NavigationAction) -> Void)? = nil) {
        self.init(request: URLRequest(url: url),
                  webViewStateModel: webViewStateModel,
                  onNavigationAction: onNavigationAction)
    }

    init(htmlString: String, baseUrl: URL?, webViewStateModel: WebViewStateModel, onNavigationAction: ((_ navigationAction: WebView.NavigationAction) -> Void)? = nil) {

        self.webViewStateModel = webViewStateModel
        self.htmlString = htmlString
        self.baseUrl = baseUrl
        self.actionDelegate = onNavigationAction
        self.request = nil
    }
}

struct WebViewWrapper : UIViewRepresentable {
    @ObservedObject var webViewStateModel: WebViewStateModel
    let action: ((_ navigationAction: WebView.NavigationAction) -> Void)?

    let request: URLRequest?
    let htmlString: String?
    let baseUrl: URL?

    init(webViewStateModel: WebViewStateModel,
         action: ((_ navigationAction: WebView.NavigationAction) -> Void)?,
         request: URLRequest? = nil, htmlString: String? = nil, baseUrl: URL? = nil) {
        self.action = action
        self.request = request
        self.htmlString = htmlString
        self.baseUrl = baseUrl
        self.webViewStateModel = webViewStateModel
    }

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = context.coordinator
        if let request = request {
            DispatchQueue.main.async {
                view.load(request)
            }
        } else if let htmlString = htmlString {
            view.loadHTMLString(htmlString, baseURL: baseUrl)
        }
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.canGoBack, webViewStateModel.goBack {
            webView.goBack()
            webViewStateModel.goBack = false
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(action: action, webViewStateModel: webViewStateModel)
    }

    final class Coordinator: NSObject {
        @ObservedObject var webViewStateModel: WebViewStateModel
        let action: ((_ navigationAction: WebView.NavigationAction) -> Void)?

        init(action: ((_ navigationAction: WebView.NavigationAction) -> Void)?,
             webViewStateModel: WebViewStateModel) {
            self.action = action
            self.webViewStateModel = webViewStateModel
        }
    }
}

extension WebViewWrapper.Coordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if action == nil {
            decisionHandler(.allow)
        } else {
            action?(.decidePolicy(navigationAction, decisionHandler))
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        webViewStateModel.loading = true
        action?(.didStartProvisionalNavigation(navigation))
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        action?(.didReceiveServerRedirectForProvisionalNavigation(navigation))

    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webViewStateModel.loading = false
        webViewStateModel.canGoBack = webView.canGoBack
        action?(.didFailProvisionalNavigation(navigation, error))
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        action?(.didCommit(navigation))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewStateModel.loading = false
        webViewStateModel.canGoBack = webView.canGoBack
        if let title = webView.title {
            webViewStateModel.pageTitle = title
        }
        action?(.didFinish(navigation))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webViewStateModel.loading = false
        webViewStateModel.canGoBack = webView.canGoBack
        action?(.didFail(navigation, error))
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if action == nil {
            completionHandler(.performDefaultHandling, nil)
        } else {
            action?(.didRecieveAuthChallange(challenge, completionHandler))
        }
    }
}
