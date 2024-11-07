//
//  ExpandingTextView.swift
//  Dwellr
//
//  Created by Adam Ali on 2/3/24.
//  Resources: https://stackoverflow.com/questions/73737704/expand-collapse-text-with-swiftui

import Foundation
import SwiftUI

struct ExpandingTextView: View {
    @State var isCollapsed = true
    @State var text = ""
    var body: some View {
//        ScrollView(.vertical, showsIndicators: false) {
            Button {
                self.isCollapsed = !self.isCollapsed
            } label: {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(self.isCollapsed ? 1 : .max)
                //                        .padding(.all, 3)
            }

//        }.fixedSize(horizontal: false, vertical: true)
        //            .frame(height: isCollapsed ? 100 : 200, alignment: .center).background(.cyan)
    }
}
