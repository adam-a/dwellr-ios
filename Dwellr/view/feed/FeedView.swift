import SwiftUI
import AVKit
import Amplify



struct FeedView: View {
    @StateObject var feedService = FeedService()
    @State var isPlaying: Bool = false
    @State var toggledPause = false
    @State var scrolledID: PreloadedPost?
    @Binding var moveToTopIndicator: Bool
    
    @Binding var selection: Int
    @Binding var currentvalues: Int
    @Binding var isPresenting: Bool
    @State private var oldSelectedTab = 0
    @State private var showFilterDialog = false
    @State var reset = false
    @State var scrolledIndex: Int?
    @State  var isLoading = true
    // Store the currently scrolled index
    
    @State private var playbackStates: [Bool] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollViewReader(content: { proxy in
                    GeometryReader { scrollGeom in
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(feedService.posts.enumerated()), id: \.offset) { index, preloadedPost in
                                    ZStack {
                                        VideoPlayer(player: preloadedPost.avPlayer, videoOverlay: { PostOverlay(post: preloadedPost.post) } )
                                            .onAppear {print("Current index for array: \(index)")
                                                if (index == 0 && !isPresenting && !reset) {
                                                    //                                            Fix an issue where non-focused videos in the feed play
                                                    if preloadedPost.avPlayer.currentItem?.status == .readyToPlay {
                                                        preloadedPost.avPlayer.play()
                                                        //                                                    isLoading = false
                                                        print("readyToPlay")
                                                        
                                                    }else {
                                                        preloadedPost.avPlayer.pause()
                                                        //                                                    isLoading = true
                                                        print("NOT readyToPlay")
                                                        
                                                        
                                                    }
                                                } else {
                                                    
                                                    preloadedPost.avPlayer.pause()
                                                }
                                            }
                                            .onDisappear {
                                                preloadedPost.avPlayer.pause() // Pause the player when the view disappears
                                            }
                                            .onReceive(preloadedPost.avPlayer.publisher(for: \.status)) { timeControlStatus in
                                                switch timeControlStatus {
                                                case .readyToPlay:
                                                    isLoading = false
                                                    print("Video is readyToPlay")
                                                    // Handle paused state if needed
                                                case .unknown:
                                                    isLoading = true
                                                    print("Video is unknown")
                                                    // Handle playing state if needed
                                                    
                                                case .failed:
                                                    isLoading = true
                                                    print("Video is failed")
                                                    // Handle playing state if needed
                                                @unknown default:
                                                    break
                                                }
                                            }
                                        
                                        // Loading Indicator
                                        
                                        if isLoading {
                                            ProgressView() // You can customize the label as needed
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        }
                                    }
                                    .scrollTargetLayout()
                                    .padding([.top,.bottom])
                                    .frame(height: scrollGeom.frame(in: .global).height)
                                }
                                switch (feedService.state) {
                                case .error:
                                    Text("Error loading posts! \(feedService.errorMessage ?? "An unknown error occurred.")")
                                case .loadedAll:
                                    Text("No more posts!")
                                case .isLoading:
                                    ProgressView().containerRelativeFrame([.horizontal, .vertical])
                                case .good:
                                    Color.clear.frame(width: 0.0, height: 0.0).onAppear { Task { try await feedService.loadVideos() } }
                                }
                            }
                            .scrollTargetLayout()
                        }.scrollPosition(id: $scrolledIndex).padding(.top)
                            .onChange(of: scrolledIndex) { oldValue, newValue in
                                if (!feedService.posts.isEmpty) {
                                    if let new = newValue {
                                        DispatchQueue.main.async {
                                            if let old = oldValue {
                                                if (self.reset) {
                                                    self.reset = false
                                                } else {
                                                    feedService.posts[old].avPlayer.pause()
                                                    feedService.posts[old].avPlayer.seek(to: .zero)
                                                }
                                            }
                                            if (new != oldValue  && !isPresenting && !reset) {
                                                feedService.posts[new].avPlayer.play()
                                                //                                                isLoading = false
                                                feedService.posts[new].avPlayer.automaticallyWaitsToMinimizeStalling = true
                                            }
                                        }
                                    }
                                }
                            }
                            .scrollIndicators(ScrollIndicatorVisibility.hidden)
                        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))}
                    .onChange(of: moveToTopIndicator) {
                        //Fix Feed index and you click again Feed the refresh data
                        print("selection values",selection)
                        scrolledIndex = 0
                    }
                    
                })
                
                
                //Fix video feed refresh function:
                .refreshable {
                    self.reset = true
                    if let index = scrolledIndex {
                        if self.feedService.posts.count > 0 {
                            self.feedService.posts[index].avPlayer.pause()
                        }
                    }
                    Task {
                        try await self.feedService.resetState()
                        scrolledIndex = 0
                    }
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    
                    Button {
                        showFilterDialog = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                        // .resizable()
                        // .frame(width: 24, height: 24)
                        // .padding()
                    }
                    
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    
                    NavigationLink {
                        Text("Some Map View")
                    } label: {
                        Image(systemName: "map")
                        // .resizable()
                        // .frame(width: 24, height: 24)
                        // .padding()
                    }
                    
                }
            }
        }.sheet(isPresented: $showFilterDialog, content: {
            Text("Here you can set different filtering")
        }).navigationViewStyle(.stack).edgesIgnoringSafeArea(.top)
            .onDisappear {
                DispatchQueue.main.async {
                    if let index = scrolledIndex {
                        if self.feedService.posts.count > 0 {
                            feedService.posts[index].avPlayer.pause()
                            feedService.posts[index].avPlayer.seek(to: .zero)
                        }
                    }
                }
            }
            .onChange(of: selection) {
                if (selection != 0 && feedService.posts.count > 0) {
                    feedService.posts[scrolledIndex ?? 0].avPlayer.pause()
                    feedService.posts[scrolledIndex ?? 0].avPlayer.seek(to: .zero)
                    scrolledIndex = 0
                }
                print("Tab \(oldSelectedTab) tapped again")
                print("Tab \(selection) tapped new")
            }
            .onChange(of: isPresenting) {
                if (isPresenting && feedService.posts.count > 0) {
                    feedService.posts[scrolledIndex ?? 0].avPlayer.pause()
                    feedService.posts[scrolledIndex ?? 0].avPlayer.seek(to: .zero)
                    scrolledIndex = 0
                }
            }
        
    }
    
    
    
}


