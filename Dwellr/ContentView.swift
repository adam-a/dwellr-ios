//
//  ContentView.swift
//  avem-prototype-v2
//
//  Created by Adam Ali on 7/16/23.
//

import SwiftUI
import AWSPluginsCore
import Amplify
import Combine

enum Tab: String {
    case firstTab
    case secondTab
    case thirdTab
    case fourthTab
}

class TabStateHandler: ObservableObject {
    @Published var tabSelected: Tab = .secondTab {
        didSet {
            if oldValue == tabSelected && tabSelected == .firstTab {
                moveFirstTabToTop.toggle()
            }
        }
    }
    @Published var moveFirstTabToTop: Bool = false

}
struct ContentView: View {

    @State private var selection: Int = 1
    @State private var currentvalues: Int = 1
    @State private var isPresenting = false
    @State private var isTabItemSelected = false
    @State private var selectedTab: Int = 0
    @State private var tappedTab: Int?
    @StateObject var tabStateHandler: TabStateHandler = TabStateHandler()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $tabStateHandler.tabSelected) {
                FeedView(moveToTopIndicator: $tabStateHandler.moveFirstTabToTop, selection: $selection,currentvalues: $currentvalues, isPresenting: $isPresenting)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Explore")
                    }.tag(Tab.firstTab)
                Text("Favorites Coming Soon!")
                    .tabItem {
                        Image(systemName: "heart")
                        Text("Saved")
                    }.tag(Tab.secondTab)

                Spacer().tag(Tab.secondTab)
                Text("Messages Coming Soon!")
                    .tabItem {
                        Image(systemName: "envelope")
                        Text("Messages")
                    }.tag(Tab.thirdTab)
                ProfileView()
                    .tabItem {
                        Image(systemName: "person")
                        Text("Profile")
                    }.tag(Tab.fourthTab)

            }.onChange(of: selection) { oldValue, newValue in
                if newValue == 2 { // replace 2 with your index
                    self.selection = 1 // reset the selection in case we somehow press the middle tab
                }
            }

            Button {
                isPresenting = true
            } label: {
                Image(systemName: "plus.app.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }.frame(width: 50, height: 50).fullScreenCover(isPresented: $isPresenting, onDismiss: {

            }) {
                NavigationView {
                    PostOnboardingView(isPresented: $isPresenting)
                }
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        ContentView()
    }
}
