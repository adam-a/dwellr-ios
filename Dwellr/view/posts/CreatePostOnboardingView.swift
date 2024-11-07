//
//  PostOnboardingView.swift
//  Dwellr
//
//  Created by Adam Ali on 8/12/23.
//

import SwiftUI

struct PostOnboardingView: View {
    @State private var selectedType: String?
    @State private var isSelectionMade: Bool = false
    @Binding var isPresented: Bool
    let types = [
        "Single Family Home",
        "Apartment",
        "Condominium",
        "Townhouse",
        "Duplex/Triplex",
        "Studio Apartment",
        "Loft",
        "Co-op",
        "Mansion",
        "Villa",
        "Cottage",
        "Bungalow",
        "Ranch Style",
        "Mobile Home",
        "Penthouse",
        "Treehouse",
        "Houseboat"
    ]

    var body: some View {

        VStack {
            Form {
                Section {
                    Picker("Type", selection: $selectedType) {
                        Text("None Selected").tag(Optional<String>(nil))
                        ForEach(types, id: \.self) {
                            Text($0).tag(Optional($0))
                        }
                    }
                }.onChange(of: selectedType) { oldValue, newValue in
                    isSelectionMade = selectedType != nil
                }.padding(5)
            }
        }

        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    CameraView(isPresented: $isPresented)
                } label: {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(isSelectionMade ? .blue : .gray)
                }.disabled(!isSelectionMade)
            }
        }.navigationTitle("Dwelling Features").navigationBarTitleDisplayMode(.inline)

    }
}

//struct PostOnboardingView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostOnboardingView()
//    }
//}
