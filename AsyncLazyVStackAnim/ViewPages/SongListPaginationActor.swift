//
//  PaginationActorBigList.swift
//  AsyncLazyVStackAnim
//
//  Created by Vanson Leung on 20/9/2023.
//

import SwiftUI

/// View to list Song list using `PaginationActor`
struct SongListPaginationActor: View {
    
    @StateObject var dataObs = KCItunesSongListObservable()
    @State var searchQuery: String = ""
    
    var body: some View {
        VStack {
            
            KCUIPaginationReader { paginationActor, paginationProxy in
                
                Text("\(paginationProxy.currentPage) \(paginationProxy.isLoading ? "T":"F") \(dataObs.items.count) \(paginationProxy.isLoadNextPageAvailable ?"T":"F")")

                ScrollViewReader { proxy in
                    List {
                        ForEach(dataObs.items, id: \.self) { it in
                            SongListCell(it: it)
                                .id(it)
                        }

                        if paginationProxy.isEnded {
                            Text("End of list")
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack {
                                ProgressView {
                                    Text("Loading...")
                                }
                                    .onAppear {
                                        if paginationProxy.isLoadNextPageAvailable {
                                            Task {
                                                await loadMoreData(actor: paginationActor)
                                            }
                                        }
                                    }
                            }
                            .zIndex(2)
                            .id("\(dataObs.items.count)-\(paginationProxy.isLoadNextPageAvailable)")
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .refreshable {
                        return await refreshData(actor: paginationActor)
                    }
                    .listStyle(.plain)
                }
                .searchable(text: $searchQuery)
                .onSubmit(of: .search) {
                    Task {
                        await refreshData(actor: paginationActor, query: searchQuery)
                    }
                }
            }
        }
        .navigationBarTitle("Songs (Pag. Actor)")
    }
    
    
    
    func fetchAPI(
        isRefresh: Bool,
        query: String?,
        actor: KCUIPaginationActor
    ) async {
        let (shouldFetch, curRefreshHash, page) = await actor.onPrepareFetch(isRefresh: isRefresh)
        
        if !shouldFetch { return }
        
        if let query = query,
           query != "" {
            dataObs.clearSongData()
        }

        let (isSuccess, songs) = await dataObs.loadSongData(
            isRefresh: isRefresh,
            page: page,
            query: query
        )
        
        await actor.onPostFetch(
            curRefreshHash: curRefreshHash,
            isRefresh: isRefresh,
            isError: !isSuccess,
            isEnded: !isSuccess || songs?.isEmpty ?? false
        )
    }
    
    func loadMoreData(actor: KCUIPaginationActor) async {
        await fetchAPI(isRefresh: false, query: nil, actor: actor)
    }
    
    func refreshData(actor: KCUIPaginationActor, query: String? = nil) async {
        await fetchAPI(isRefresh: true, query: query, actor: actor)
    }
    
    
    
}


