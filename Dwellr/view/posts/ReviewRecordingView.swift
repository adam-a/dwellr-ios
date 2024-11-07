//
//  PostEditView.swift
//  avem-prototype-v2
//
//  Created by Adam Ali on 7/19/23.
//

import SwiftUI
import AVKit

struct PostReviewView: View {
    var trackData: [Int: CaptureData] = [:]
    @State var mergedUrlState: URL?
    @State private var transcript: String = ""
    var player = AVPlayer()
    @Binding var isPresented: Bool
    var body: some View {
        NavigationView {
            ZStack {
                if let url = mergedUrlState {
                    VideoPlayer(player: player)
                        .onAppear{
                            if player.currentItem == nil {
                                let item = AVPlayerItem(url: url)
                                player.replaceCurrentItem(with: item)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                player.play()
                            })
                        }.onDisappear {
                            DispatchQueue.main.async {
                                player.pause()
                            }
                        }
                } else {
                    ProgressView("Loading...")
                }
            }.onAppear {

                var assetsToMerge = Array<CaptureData>()
                for index in 0...trackData.keys.count {
                    if let data = trackData[index] {
                        assetsToMerge.append(data)
                        transcript.append(contentsOf: data.transcript)
                    }
                }
                mergeVideos(captureData: assetsToMerge, outputURL: tempURLForVideo()) { mergedURL, error in
                    if let mergedURL = mergedURL {
                        self.mergedUrlState = mergedURL
                        print("Merging successful. Merged video URL: \(mergedURL)")
                    } else if let error = error {
                        print("Error while merging videos: \(error.localizedDescription)")
                    }
                }

            }
        }.navigationTitle("Review Your Video")
            .toolbar {
                NavigationLink("Next") {
                    ReviewPostView(transcript: transcript, videoUri: self.mergedUrlState, isPresented: $isPresented)
                }

            }


    }
}

//struct PostReviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostReviewView(trackData: [:])
//    }
//}
