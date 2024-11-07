//
//  FeedService.swift
//  Dwellr
//
//  Created by Adam Ali on 10/9/23.
//

import Foundation
import Amplify
import AVKit

struct PreloadedPost: Hashable {
    static func == (lhs: PreloadedPost, rhs: PreloadedPost) -> Bool {
        return lhs.post.id == rhs.post.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(post.id)
    }

    let post: Post
    let avPlayer: AVPlayer
}

class FeedService: ObservableObject {

    enum State: Int {
        case good = 0
        case isLoading = 1
        case error = 2
        case loadedAll = 3
    }

    @Published var errorMessage: String?  // Add an error message property

    @Published var posts: [PreloadedPost] = []
    @Published private(set) var state = State.good

    var page: Int = 0
    let limit: Int = 5

    init() {
        Task { try await loadVideos() }
    }

    static func getMetadataJson(metadata: PostMetadata) -> String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(metadata)
            let string = String(data: data, encoding: .utf8)
            if let res = string {
                return res
            }
            return ""
        } catch {
            return ""
        }
    }

    func resetState() async throws {
        DispatchQueue.main.async {
            self.state = .good
            self.posts = []
        }
        self.page = 0
        try await loadVideos()
    }

    //Old Code
    //    func loadVideos() async throws {
    //
    //        guard state == State.good else {
    //            return
    //        }
    //        DispatchQueue.main.async {
    //            self.state = State.isLoading
    //        }
    //        let offset = page * limit
    //
    //        do {
    //            let fetchedPosts = try await getPosts(offset: offset, limit: limit)
    //            DispatchQueue.main.async {
    //                self.state = (fetchedPosts.count == self.limit) ? .good : .loadedAll
    //            }
    //            self.page+=1
    //            let preloadedPosts: [PreloadedPost] = fetchedPosts.reduce(into: [PreloadedPost]()) { (result, post) in
    //                if let url = URL(string: "https://dwellr.s3.us-east-1.amazonaws.com/\(post.mediaKey).mp4") {
    //                    print("url play link",url);
    //                    result.append(PreloadedPost(post: post, avPlayer: AVPlayer(url: url)))
    //                }
    //            }
    //            DispatchQueue.main.async {
    //                self.posts.append(contentsOf: preloadedPosts)
    //            }
    //
    //        } catch let error {
    //            DispatchQueue.main.async {
    //                self.state = State.error
    //                self.errorMessage = error.localizedDescription
    //            }
    //        }
    //
    //    }

    func loadVideos() async throws {
        guard state != .isLoading else {
            return
        }

        // Set the state to loading on the main queue
        DispatchQueue.main.async {
            self.state = .isLoading
        }

        // Perform data fetching on a background queue
        do {
            let fetchedPosts = try await getPosts(offset: page * limit, limit: limit)

            // Update UI on the main queue
            DispatchQueue.main.async {
                self.state = (fetchedPosts.count == self.limit) ? .good : .loadedAll
                self.page += 1

                let preloadedPosts: [PreloadedPost] = fetchedPosts.compactMap { post in
                    guard let url = URL(string: "https://dwellr.s3.us-east-1.amazonaws.com/\(post.mediaKey).mp4") else {
                        return nil
                    }
                    print("url play link", url)
                    return PreloadedPost(post: post, avPlayer: AVPlayer(url: url))
                }
                self.posts.append(contentsOf: preloadedPosts)
            }

        } catch let error {
            // Handle errors on the main queue
            DispatchQueue.main.async {
                self.state = .error
                self.errorMessage = error.localizedDescription
            }
        }
    }

}
