//
//  SongListCell.swift
//  AsyncLazyVStackAnim
//
//  Created by Vanson Leung on 20/9/2023.
//

import SwiftUI


struct SongListCell: View {
    var it: GenericListItemViewModel
    @State var isStarted = false
    var body: some View {
        VStack {
            if isStarted {
                Text("\(it.title ?? "")")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.scale(scale: 0))
                Text("\(it.subtitle ?? "")")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.scale(scale: 0))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            Task.detached {
                withAnimation {
                    isStarted = true
                }
            }
        }
    }
}

