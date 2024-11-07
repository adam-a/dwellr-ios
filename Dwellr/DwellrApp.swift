//
//  avem_prototype_v2App.swift
//  avem-prototype-v2
//
//  Created by Adam Ali on 7/16/23.
//

import SwiftUI
import Amplify
import Authenticator
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin
import AuthenticationServices
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        return true
    }
}


@main
struct DwellrApp: App {

    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            Amplify.Logging.logLevel = .verbose
            try Amplify.configure()
        } catch {
            print("Unable to configure Amplify \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Authenticator { state in
                ContentView()
            }
        }
    }
}
