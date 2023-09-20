//
//  KCItunesSongListObs.swift
//  AsyncLazyVStackAnim
//
//  Created by Vanson Leung on 20/9/2023.
//

import SwiftUI
import KeysocItunesSearchAPIServiceiOS_Swift

@MainActor
class KCItunesSongListObservable: ObservableObject {
    @Published var items: [GenericListItemViewModel] = []
    
    var query: String?
    
    func clearSongData() {
        self.items.removeAll()
    }
    
    func loadSongData(
        isRefresh: Bool,
        page: Int,
        query: String? = nil
    ) async -> (isSuccess: Bool, songs: [KCItunesSong]?) {

        await Task.sleep(1 * 1_000_000_000)
        
//        var _items: [GenericListItemViewModel]? = items
        
        if let query = query {
            self.query = query
        }

        do {
            let query = self.query ?? ""
            let itemsPerPage = 100
            let selectedMediaTypeValue = "music"
            let selectedCountryValue = "HK"
            let seelectedLang = "zh_hk"
            
            let songs = try await KCITunesAPIQueryServiceAsync.shared.searchSongs(
                withQuery: query,
                limit: itemsPerPage,
                offset: page * (itemsPerPage),
                mediaType: selectedMediaTypeValue,
                country: selectedCountryValue,
                lang: seelectedLang
            )
            
            if isRefresh {
                self.items.removeAll()
            }
            
            // Append the viewmodel list
            if page == 0 || isRefresh {
                let itemStream = AsyncStream<GenericListItemViewModel> { continuation in
                    Task.detached {
                        for song in songs {
                            let item = GenericListItemViewModel(song: song)
                            await Task.sleep(10 * 1_000_000)
                            continuation.yield(item)
                        }
                        continuation.finish()
                    }
                }
                
                for await item in itemStream {
                    self.items.append(item)
                }
            } else {
                self.items.append(contentsOf: songs.map({ song in
                    GenericListItemViewModel(song: song)
                }))
            }

            return (true, songs)
            
        } catch {
            return (false, nil)
        }
    }
}


