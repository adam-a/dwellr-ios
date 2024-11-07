//
//  ProfileView.swift
//  Dwellr
//
//  Created by Adam Ali on 8/10/23.
//

import SwiftUI
import Amplify

struct ProfileView: View {

    @State private var selectedType: String = "Tennant"
    let types = [
        "Landlord"
    ]

    @State private var firstName : String = "Adam"
    @State private var lastName : String = "Ali"
    @State private var phoneNumber : String = "555-555-5555"

    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.circle").resizable().padding().frame(width: 96, height: 96)
                Form {
                    Section {

                        TextField(firstName, value: $firstName, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)


                        TextField(lastName, value: $lastName, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)

                        TextField(phoneNumber, value: $phoneNumber, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)

                        Picker("Current View", selection: $selectedType) {
                            Text("Tennant").tag("Tennant")
                            ForEach(types, id: \.self) {
                                Text($0).tag(Optional($0))
                            }
                        }
                    }.padding(5)
                }
                Text("User's Live Posts Here").padding(5)
            }.toolbar {
                HStack {
                    NavigationLink {
                        Text("View with user's expired/archived videos")
                    } label: {
                        Image(systemName: "archivebox")

                    }
                    Spacer()
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")

                    }
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
