//
//  SettingsView.swift
//  Dwellr
//
//  Created by Adam Ali on 8/10/23.
//

import SwiftUI
import Amplify

struct SettingsView: View {

    @State private var showAlert = false
    var body: some View {
        VStack {
            Spacer()
            Button(action: {
                showAlert = true
            }) {
                Text("Sign out")
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
        }.alert(isPresented: $showAlert) {
            Alert(
                title: Text("Sign Out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .default(Text("Cancel")),
                secondaryButton: .destructive(Text("Sign Out"), action: {
                    Task {
                        await Amplify.Auth.signOut()
                    }
                })
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
