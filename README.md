# SwiftUI-Sample-AsyncListAnim

A demo of using ObservableObject and Actor to load paginated List items


## Project dependencies

- https://github.com/VansonLeung/KeysocItunesSearchAPIServiceiOS-Swift


## Demo video

https://github.com/VansonLeung/SwiftUI-Sample-AsyncListAnim/assets/1129695/7090e722-1585-4045-8caf-4deafe38420e



## Concurrency - Async / await usages

```swift

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

```

```swift

//
//  KCITunesAPINetworkService.swift
//  
//
//  Created by Vanson Leung on 12/9/2023.
//

import Foundation

class KCITunesAPINetworkService {
    static let shared = KCITunesAPINetworkService()

    private init() {}

    func performRequest<T: Codable>(
        _ request: URLRequest,
        decodingType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(KCItunesConstants.NetworkError.noData))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedData = try decoder.decode(decodingType, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func performRequestAsync<T: Codable>(
        _ request: URLRequest,
        decodingType: T.Type
    ) async throws -> T {
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let decodedData = try decoder.decode(decodingType, from: data)
            return decodedData
        } catch {
            throw error
        }
    }


}


```




## Concurrency - Continuation usages

```swift
    /// Prepare the pagination view model to load the next request (next page or refresh)
    ///
    /// - Parameters:
    ///   - isRefresh: whether the next request is refresh or load-more
    ///   - completion: callback of:
    ///     - shouldFetch: `Bool` whether the next request should be called or not
    ///     - curRefreshHash: `Int` to identify each refresh action
    ///     - page: `Int` to return the current page (or return 0 for refresh action)
    func onPrepareFetch(
        isRefresh: Bool,
        completion: @escaping (_ shouldFetch: Bool, _ curRefreshHash: Int, _ page: Int) -> Void)
    {

        ...

        return completion(true, curRefreshHash, page)
    }
    
    /// [Concurrency] Prepare the pagination view model to load the next request (next page or refresh)
    ///
    /// - Parameters:
    ///   - isRefresh: whether the next request is refresh or load-more
    ///
    /// - Returns:
    ///   - shouldFetch: `Bool` whether the next request should be called or not
    ///   - curRefreshHash: `Int` to identify each refresh action
    ///   - page: `Int` to return the current page (or return 0 for refresh action)
    func onPrepareFetchAsync(
        isRefresh: Bool
    ) async -> (shouldFetch: Bool, curRefreshHash: Int, page: Int)
    {
        return await withCheckedContinuation { continuation in
            onPrepareFetch(
                isRefresh: isRefresh,
                completion: { shouldFetch, curRefreshHash, page in
                    continuation.resume(returning: (shouldFetch, curRefreshHash, page))
                }
            )
        }
    }
    
```


## Concurrency - AsyncStream usages

```swift

    ...

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

    ...

```







## Demonstrations of List pagination approaches

### 1. ObservableObject approach (recommended, suitable for most SwiftUI state bindings)

#### KCUIPaginationObservable

```swift
@MainActor
class KCUIPaginationObservable: ObservableObject {
    
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

...

```


#### Usage

```swift

    @StateObject var paginationObs = KCUIPaginationObservable()

...

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

```


### 2. Actor approach (Concurrency, suitable for asynchronous logic cases where omitting all race conditions is critical)

- As Actor variables cannot be accessed directly, in this example - I made a `KCUIPaginationReader` for the children Views to read the Actor data
- The `KCUIPaginationReader` usage structure conceptually resembles the React Provider pattern - a mechanism for components within your SwiftUI hierarchy to access shared data or state.

#### KCUIPaginationActor, KCUIPaginationActor.Proxy

```swift
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

...


```

#### KCUIPaginationReader

```swift
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

```


#### Usage

```swift

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

```





