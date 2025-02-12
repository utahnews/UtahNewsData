//
//  ContactInfo.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

import SwiftUI

public struct ContactInfo: Codable, Identifiable, Hashable, Equatable {
    public var id: String = UUID().uuidString
    public var name: String? = nil
    public var email: String? = nil
    public var website: String? = nil
    public var phone: String? = nil
    public var address: String? = nil
    public var socialMediaHandles: [String: String]? = [:]  // e.g., ["Twitter": "@username"]
    
    public init( name: String? = nil, email: String? = nil, website: String? = nil, phone: String? = nil, address: String? = nil, socialMediaHandles: [String: String]? = [:]) {
        self.name = name
        self.email = email
        self.website = website
        self.phone = phone
        self.address = address
        self.socialMediaHandles = socialMediaHandles
        
    }
}
