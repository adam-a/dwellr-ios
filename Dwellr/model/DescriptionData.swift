//
//  DescriptionData.swift
//  Dwellr
//
//  Created by Adam Ali on 8/23/23.
//

import Foundation

struct DescriptionData: Codable {
    let includesParking: Bool?
    let leaseAvailabilityDate: Date?
    let lengthOfLeaseInMonths: Int?
    let petsAllowed: Bool?
    let price: Int?
    let sqft: Int?
}
