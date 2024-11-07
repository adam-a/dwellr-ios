//
//  PostDetailsView.swift
//  Dwellr
//
//  Created by Adam Ali on 1/28/24.
//

import Foundation
import SwiftUI

struct PostOverlay: View {
    @State private var showAlert = false
    @State var post: Post?
    var body: some View {
        VStack(alignment: .trailing) {
            Button {
                showAlert = true
            } label: {
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .padding()

            }
            Spacer()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight:0, maxHeight: .infinity, alignment: Alignment.topLeading)
            HStack {
                HStack(alignment: .center) {
                    NavigationLink {
                        Text("The poster's profile")
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()

                    }
                    ExpandingTextView(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam vel elit in justo congue vestibulum a quis turpis. Nunc a odio at purus sagittis rhoncus tincidunt et ligula. Nullam dictum et turpis in blandit. Quisque in magna turpis. Suspendisse bibendum dui eleifend tincidunt dapibus. Donec nec eleifend lacus, sit amet fringilla sem")

                }
                VStack {
                    VStack(spacing: -4) {
                        Button {

                        } label: {

                            Image(systemName: "heart")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding()

                        }
                        Text("231")
                    }


                    VStack(spacing: -4) {
                        Button {

                        } label: {

                            Image(systemName: "bubble")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding()

                        }
                        Text("51")
                    }
                }
            }


        }
        .sheet(isPresented: $showAlert, content: {
            if let metadata = post?.metadata {
                Text(FeedService.getMetadataJson(metadata: metadata))
            } else {
                Text("No metadata found")
            }

        })
    }
}

