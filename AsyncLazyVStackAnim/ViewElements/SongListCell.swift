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
            VStack {
                Text("\(it.title ?? "")")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(it.subtitle ?? "") \(isStarted ?"T":"F")")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(isStarted ? 1 : 0)
            .scaleEffect(CGSize(width: isStarted ? 1 : 0, height: isStarted ? 1 : 0))
        }
        .animation(.default, value: isStarted)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            withAnimation {
                isStarted = true
            }
        }
    }
}

