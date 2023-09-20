//
//  GenericListItemViewModel.swift
//  AsyncLazyVStackAnim
//
//  Created by Vanson Leung on 20/9/2023.
//

import Foundation
import KeysocItunesSearchAPIServiceiOS_Swift

class GenericListItemViewModel: NSObject {
    
    var title: String?
    var subtitle: String?
    
    init(song: KCItunesSong) {
        self.title = song.trackName
        self.subtitle = song.artistName
    }
}
