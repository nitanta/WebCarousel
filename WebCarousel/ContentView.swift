//
//  ContentView.swift
//  WebCarousel
//
//  Created by Nitanta Adhikari on 18/08/2023.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var webViewStateModel: WebViewStateModel = WebViewStateModel()

    var body: some View {
        CarouselWrapperView(webViewStateModel: webViewStateModel)
            .frame(maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
