//
//  ContentView.swift
//  AsyncLazyVStackAnim
//
//  Created by Vanson Leung on 20/9/2023.
//

import SwiftUI
import KeysocItunesSearchAPIServiceiOS_Swift


struct ContentView: View {
    
    @StateObject var _lbObs = AppRootNavigationViewLinkBundleObs()

    var body: some View {
        NavigationView {
            VStack {
                
                
                Button {
                    _lbObs.openAnyView(item: SongListPaginationObservable().anyView, animated: true)
                } label: {
                    Text("1. Load song list (List using Pagination Observable)")
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 18)

                
                
                Button {
                    _lbObs.openAnyView(item: SongListPaginationActor().anyView, animated: true)
                } label: {
                    Text("2. Load song list (List using Pagination Actor)")
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 18)

                
                Spacer()
                
            }
            .asDetailsView(linkBundleObs: _lbObs)
            .navigationTitle("Home")
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}











