//
//  Posts.swift
//  Dwellr
//
//  Created by Adam Ali on 10/8/23.
//
import Foundation

struct PostMetadata: Codable {
    let includesParking: Bool?
    let leaseAvailabilityDate: String?
    let lengthOfLeaseInMonths: Int?
    let petsAllowed: Bool?
    let price: Double?
    let sqft: Double?
    let generatedDescription: String?
    let bedroomCount: Int?
    let bathroomCount: Int?
    let furnished: Bool?
    let kitchen: Bool?
    let appliances: String?
    let amenities: String?
    let yard: Bool?
    let location: String?
    let utilitiesIncluded: Bool?
}

struct Post: Codable, Identifiable {
    let id: String
    let createdAt: Date
    let updatedAt: Date
    let username: String
    let mediaKey: String
    let metadata: PostMetadata
}

struct CreatePostBody: Codable {
    let mediaKey: String
    let metadata: PostMetadata
}

struct GenerateDescriptionBody: Codable {
    let transcript: String
}


struct GenerateDescriptionResponse: Codable {
    let transcript: String
}

struct PresignResponse: Codable {
    let presignedUrl: String
    let key: String
}
