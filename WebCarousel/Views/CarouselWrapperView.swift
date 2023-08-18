//
//  SubscriptionCarouselWrapperView.swift
//  WebCarousel
//
//  Created by Nitanta Adhikari on 18/08/2023.
//

import SwiftUI

struct CarouselWrapperView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State var webViewStateModel: WebViewStateModel = WebViewStateModel()

    var body: some View {
        VStack {
            ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
                carouselHtml.map({
                    WebView(htmlString: $0, baseUrl: carouselBaseUrl,
                            webViewStateModel: self.webViewStateModel)
                        .disabled(true)
                })
            }
        }.frame(maxHeight: .infinity)
    }

    var carouselBaseUrl: URL? {
        return Bundle.main.bundleURL.appendingPathComponent("subscription_carousel", isDirectory: true)
    }

    var carouselUrl: URL? {
        return carouselBaseUrl?.appendingPathComponent("index.html")
    }

    /// Load the HTML file as a string and substitute the keys for localised values
    var carouselHtml: String? {
        if let carouselUrl = carouselUrl, let carouselHtmlData = try? Data(contentsOf: carouselUrl), let htmlString = String(data: carouselHtmlData, encoding: .utf8) {

            var carouselHtmlString = htmlString
            for captionIndex in 1...8 {
                let captionIndexKey = "subscription.carousel.tagline.\(captionIndex)"
                carouselHtmlString = carouselHtmlString.replacingOccurrences(of: captionIndexKey, with: NSLocalizedString(captionIndexKey, comment: ""))
            }

            return carouselHtmlString
        }

        return nil
    }
}
