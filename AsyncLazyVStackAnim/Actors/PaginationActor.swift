//
//  PaginationActor.swift
//  AsyncLazyVStackAnim
//
//  Created by Vanson Leung on 20/9/2023.
//

import SwiftUI

actor KCUIPaginationActor {
    
    struct Proxy {
        /// actor
        var actor: KCUIPaginationActor?
        
        /// current page of the list data fetch
        var currentPage = 0
        
        /// loading busy status
        var isLoading = false
        
        /// refreshing busy status
        var isRefreshing = false
        
        /// whether the list data is ended
        var isEnded = false
        
        /// whether the list data encounters an error
        var isError = false
        
        /// used for identifying each refresh action
        var refreshHash: Int = 1
        
        /// State function to determine whether the pagination view model can load next page
        var isLoadNextPageAvailable: Bool {
            return !isEnded && !isLoading && !isRefreshing && !isError
        }
    }
    
    /// current page of the list data fetch
    var currentPage = 0
    
    /// loading busy status
    var isLoading = false
    
    /// refreshing busy status
    var isRefreshing = false
    
    /// whether the list data is ended
    var isEnded = false
    
    /// whether the list data encounters an error
    var isError = false
    
    /// used for identifying each refresh action
    var refreshHash: Int = 1
    
    
    var completion: ((_ actor: KCUIPaginationActor, _ proxy: Proxy) -> Void)?
    
    init(completion: ( (_ actor: KCUIPaginationActor, _ proxy: Proxy) -> Void)?) {
        self.completion = completion
    }
    
    
    
    
    /// Prepare the pagination view model to load the next request (next page or refresh)
    ///
    /// - Parameters:
    ///   - isRefresh: whether the next request is refresh or load-more
    ///
    /// - Returns:
    ///   - shouldFetch: `Bool` whether the next request should be called or not
    ///   - curRefreshHash: `Int` to identify each refresh action
    ///   - page: `Int` to return the current page (or return 0 for refresh action)
    func onPrepareFetch(
        isRefresh: Bool
    ) -> (shouldFetch: Bool, curRefreshHash: Int, page: Int)
    {
        if isRefreshing {
            return (false, -1, -1)
        }
        
        if isRefresh {
            isRefreshing = true
            isError = false
            isEnded = false
        } else {
            if isEnded {
                return (false, -1, -1)
            }
            if isLoading {
                return (false, -1, -1)
            }
            isLoading = true
        }
        

        // assign runtime values here
        let curRefreshHash = refreshHash
        let page = isRefresh ? 0 : currentPage
        
        completion?(self, fetchState())
        return (true, curRefreshHash, page)
    }
    
    
    
    
    /// Post-process the pagination view model to end the current request
    ///
    /// - Parameters:
    ///   - curRefreshHash: input of `curRefreshHash` from `onPrepareFetch(..)`
    ///   - isRefresh: input of `isRefresh` from `onPrepareFetch(..)`
    ///   - isError: `Bool` to indicate if the request has error (e.g. API error)
    ///   - isEnded: `Bool` to indicate if the request has ended (e.g. last page has reached, no more results)
    func onPostFetch(
        curRefreshHash: Int,
        isRefresh: Bool,
        isError: Bool,
        isEnded: Bool
    ) {
        // post-processing error
        if isError {
            self.isError = true
            self.isRefreshing = false
            self.isLoading = false
        }
        
        // post-processing refresh
        else if isRefresh {

            if self.refreshHash == curRefreshHash {
                // update
                self.currentPage = 1
                self.refreshHash += 1
                self.isRefreshing = false
                self.isLoading = false
                self.isEnded = isEnded
            }
        }
        
        // post-processing loading
        else {

            // check refresh hash:
            // if hash is unchanged, load more is valid
            if self.refreshHash == curRefreshHash {
                // update
                self.currentPage += 1
                self.isLoading = false
                self.isEnded = isEnded
            }

        }
        
        completion?(self, fetchState())
    }
    
    
    
    func fetchState() -> Proxy {
        return Proxy(
            currentPage: currentPage,
            isLoading: isLoading,
            isRefreshing: isRefreshing,
            isEnded: isEnded,
            isError: isError,
            refreshHash: refreshHash
        )
    }
}


@MainActor
struct KCUIPaginationReader<Content: View>: View {
    private var content: (
        _ actor: KCUIPaginationActor,
        _ proxy: KCUIPaginationActor.Proxy
    ) -> Content

    @State private var proxy = KCUIPaginationActor.Proxy()
    
    @State private var paginationActor: KCUIPaginationActor?
    
    init(@ViewBuilder content: @escaping (KCUIPaginationActor, KCUIPaginationActor.Proxy) -> Content) {
        self.content = content
    }

    var body: some View {
        VStack {
            if let actor = self.paginationActor {
                content(actor, proxy)
            }
        }
        .onAppear {
            self.paginationActor = KCUIPaginationActor(completion: { a, p in
                self.proxy = p
            })
        }
    }
}
