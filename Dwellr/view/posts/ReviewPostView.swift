//
//  CreatePostView.swift
//  Dwellr
//
//  Created by Adam Ali on 8/10/23.
//

import SwiftUI

enum MyError: Error {
    case someError(message: String)
}

struct ReviewPostView: View {
    var transcript: String
    var videoUri: URL?
    @State private var includesParking = false
    @State private var leaseAvailabilityDate = Date()
    @State private var lengthOfLeaseInMonths = 0
    @State private var petsAllowed = false
    @State private var price = 0.0
    @State private var sqft = 0.0
    @Binding var isPresented: Bool
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var metadataDump = ""

    @State private var generatedDescription: String = ""
    @State private var bedroomCount: Int = 0
    @State private var bathroomCount: Int = 0
    @State private var furnished: Bool = false
    @State private var kitchen: Bool = false
    @State private var appliances: String = ""
    @State private var amenities: String = ""
    @State private var yard: Bool = false
    @State private var location: String = ""
    @State private var utilitiesIncluded: Bool = false

    var body: some View {
        NavigationView {
            if (isLoading) {
                ProgressView("Loading...")
            } else {
                VStack {
                    Form {
                        Section(header: Text("Property Details")) {
                            DatePicker("Lease Availability Date", selection: $leaseAvailabilityDate, displayedComponents: .date)
                            Stepper("Lease Length (months): \(lengthOfLeaseInMonths)", value: $lengthOfLeaseInMonths, in: 1...72)
                            Toggle("Includes Parking", isOn: $includesParking)
                            Toggle("Pets Allowed", isOn: $petsAllowed)

                            VStack(alignment: .center) {
                                Text("Price ($)")
                                    .font(.headline).frame(maxWidth: .infinity, alignment: .center)
                                TextField("Price", value: $price, formatter: NumberFormatter())
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .center) {
                                Text("Sqft")
                                    .font(.headline).frame(maxWidth: .infinity, alignment: .center)
                                TextField("Sqft", value: $sqft, formatter: NumberFormatter())
                                    .textFieldStyle(.roundedBorder)
                            }

                            Stepper("Bedroom Count: \(bedroomCount)", value: $bedroomCount, in: 1...10)
                            Stepper("Bathroom Count: \(bathroomCount)", value: $bathroomCount, in: 1...10)
                            Toggle("Furnished", isOn: $furnished)
                            Toggle("Kitchen", isOn: $kitchen)
                            Toggle("Yard", isOn: $yard)
                            Toggle("Utilities Included", isOn: $utilitiesIncluded)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Appliances")
                                    .font(.headline)
                                TextField("Appliances", value: $appliances, formatter: NumberFormatter())
                                    .textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Amenities")
                                    .font(.headline)
                                TextField("Amenities", value: $amenities, formatter: NumberFormatter())
                                    .textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Description")
                                    .font(.headline)
                                TextField("Description", text: $generatedDescription, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .padding()
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DEBUG DUMPS")
                                    .font(.headline).bold().frame(maxWidth: .infinity, alignment: .center)
                                Text(metadataDump)
                                    .lineLimit(nil)
                                Text(errorMessage)
                                    .lineLimit(nil)
                            }
                        }
                    }
                }
            }



        }.navigationBarTitle("Create Post", displayMode: .inline).onAppear {
            isLoading = true
            Task {
                do {
                    let metadata = try await generateDescription(transcript: transcript)
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try encoder.encode(metadata)
                    metadataDump = String(data: data, encoding: .utf8)!
                    populateFields(with: metadata)
                } catch {
                    print("Error: \(error)")
                }
                isLoading = false
            }
        }.toolbar {
            ToolbarItemGroup {

                Button {
                    self.isLoading = true
                    self.errorMessage = ""
                    Task {

                        do {
                            if let uri = videoUri {
                                let presignedUrlResponse = try await getPresignedUploadUrl()
                                if let uploadUri = URL(string: presignedUrlResponse.presignedUrl) {
                                    let result = try await uploadToS3(uri, toPresignedURL: uploadUri)
                                    switch result {
                                    case .success(let res):
                                        print(res)
                                    case .failure(let error):
                                        throw error
                                    }
                                    let postMetadata = PostMetadata(includesParking: self.includesParking, leaseAvailabilityDate: self.leaseAvailabilityDate.ISO8601Format(), lengthOfLeaseInMonths: self.lengthOfLeaseInMonths, petsAllowed: self.petsAllowed, price: self.price, sqft: self.sqft, generatedDescription: self.generatedDescription, bedroomCount: self.bedroomCount, bathroomCount: self.bathroomCount, furnished: self.furnished, kitchen: self.kitchen, appliances: self.appliances, amenities: self.amenities, yard:  self.yard, location: self.location, utilitiesIncluded: self.utilitiesIncluded)
                                    let postBody = CreatePostBody(mediaKey: presignedUrlResponse.key, metadata: postMetadata)
                                    try await createPost(createPostBody: postBody)
                                    isPresented = false
                                }

                            }

                        } catch let error {
                            print("Post Create Error", error.localizedDescription)
                            self.errorMessage = error.localizedDescription
                        }

                        self.isLoading = false
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .resizable()
                        .foregroundColor(self.isLoading ? .gray : .green)
                        .disabled(self.isLoading)
                        .frame(width: 28, height: 24)
                        .padding()

                }
            }
        }
    }

    private func populateFields(with data: PostMetadata) {
        includesParking = data.includesParking ?? false

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        dateFormatter.timeZone = TimeZone.current // Or set the appropriate time zone

        if let unwrappedLeaseDate = data.leaseAvailabilityDate {
            if let parsedDate = dateFormatter.date(from: unwrappedLeaseDate) {
                leaseAvailabilityDate = parsedDate
            }
        }

        lengthOfLeaseInMonths = data.lengthOfLeaseInMonths ?? 0
        petsAllowed = data.petsAllowed ?? false
        price = data.price ?? 0.0
        sqft = data.sqft ?? 0.0
        bedroomCount = data.bedroomCount ?? 0
        bathroomCount = data.bathroomCount ?? 0
        generatedDescription = data.generatedDescription ?? ""
        yard = data.yard ?? false
        kitchen = data.kitchen ?? false
        furnished = data.furnished ?? false
        utilitiesIncluded = data.utilitiesIncluded ?? false
        amenities = data.amenities ?? ""
        appliances = data.appliances ?? ""
    }
}


//struct ReviewPostView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReviewPostView(transcript:"test", isPresented: Binding(false))
//    }
//}
