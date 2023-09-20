//
//  PaginationObservableBigList.swift
//  AsyncLazyVStackAnim
//
//  Created by Vanson Leung on 20/9/2023.
//

import SwiftUI

/// View to list Song list using `PaginationObservable`
struct SongListPaginationObservable: View {
    
    @StateObject var dataObs = KCItunesSongListObservable()
    @StateObject var paginationObs = KCUIPaginationObservable()
    @State var searchQuery: String = ""

    var body: some View {
        VStack {
            
            Text("\(paginationObs.currentPage) \(paginationObs.isLoading ? "T":"F") \(dataObs.items.count) \(paginationObs.isLoadNextPageAvailable ?"T":"F")")

            ScrollViewReader { proxy in
                List {
                    ForEach(dataObs.items, id: \.self) { it in
                        SongListCell(it: it)
                            .id(it)
                    }

                    if paginationObs.isEnded {
                        Text("End of list")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack {
                            ProgressView {
                                Text("Loading...")
                            }
                                .onAppear {
                                    if paginationObs.isLoadNextPageAvailable {
                                        Task {
                                            await loadMoreData(paginationObs: paginationObs)
                                        }
                                    }
                                }
                        }
                        .zIndex(2)
                        .id("\(dataObs.items.count)-\(paginationObs.isLoadNextPageAvailable)")
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .refreshable {
                    return await refreshData(paginationObs: paginationObs)
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $searchQuery)
        .onSubmit(of: .search) {
            Task {
                await refreshData(paginationObs: paginationObs, query: searchQuery)
            }
        }
        .navigationBarTitle("Songs (Pag. Obs.)")
    }
    
    
    
    func fetchAPI(
        isRefresh: Bool,
        query: String? = nil,
        paginationObs: KCUIPaginationObservable
    ) async {
        let (shouldFetch, curRefreshHash, page) = await paginationObs.onPrepareFetchAsync(isRefresh: isRefresh)
        
        if !shouldFetch { return }
        
        if let query = query,
           query.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            dataObs.clearSongData()
        }
        
        let (isSuccess, songs) = await dataObs.loadSongData(
            isRefresh: isRefresh,
            page: page,
            query: query
        )
        
        await paginationObs.onPostFetchAsync(
            curRefreshHash: curRefreshHash,
            isRefresh: isRefresh,
            isError: !isSuccess,
            isEnded: !isSuccess || songs?.isEmpty ?? false
        )
    }
    
    func loadMoreData(paginationObs: KCUIPaginationObservable) async {
        await fetchAPI(isRefresh: false, paginationObs: paginationObs)
    }
    
    func refreshData(paginationObs: KCUIPaginationObservable, query: String? = nil) async {
        await fetchAPI(isRefresh: true, query: query, paginationObs: paginationObs)
    }
    
    
    
    
}


