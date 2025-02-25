//
//  ContactInfo.swift
//  UtahNewsData
//
//  Created by Mark Evans on 2/12/25.
//

/*
 # ContactInfo Model
 
 This file defines the ContactInfo model, which represents contact information
 for entities in the UtahNewsData system. It can be used with various entity types,
 particularly with Organization and Person entities.
 
 ## Key Features:
 
 1. Basic contact details (name, email, phone)
 2. Web presence (website)
 3. Physical location (address)
 4. Social media presence
 
 ## Usage:
 
 ```swift
 // Create basic contact information
 let contact = ContactInfo(
     name: "Media Relations",
     email: "media@example.com",
     phone: "801-555-1234"
 )
 
 // Create detailed contact information with social media
 let detailedContact = ContactInfo(
     name: "John Smith",
     email: "john@example.com",
     website: "https://johnsmith.example",
     phone: "801-555-5678",
     address: "123 Main St, Salt Lake City, UT 84101",
     socialMediaHandles: [
         "Twitter": "@johnsmith",
         "LinkedIn": "john-smith-utah"
     ]
 )
 
 // Use with an Organization
 let organization = Organization(
     name: "Utah News Network",
     orgDescription: "A news organization covering Utah news",
     contactInfo: [contact, detailedContact]
 )
 ```
 
 ContactInfo is designed to be flexible and can represent different types of
 contact points, from general department contacts to specific individual contacts.
 */

import SwiftUI

/// Represents contact information for entities in the news data system.
/// This can be used with various entity types, particularly with
/// Organization and Person entities.
public struct ContactInfo: Codable, Identifiable, Hashable, Equatable {
    /// Unique identifier for the contact information
    public var id: String = UUID().uuidString
    
    /// Name of the contact (person or department)
    public var name: String? = nil
    
    /// Email address for contact
    public var email: String? = nil
    
    /// Website URL
    public var website: String? = nil
    
    /// Phone number for contact
    public var phone: String? = nil
    
    /// Physical address
    public var address: String? = nil
    
    /// Dictionary of social media platforms and corresponding handles
    /// Example: ["Twitter": "@username", "LinkedIn": "profile-name"]
    public var socialMediaHandles: [String: String]? = [:]
    
    /// Creates new contact information with the specified properties.
    /// All properties are optional to allow for flexible contact representation.
    /// 
    /// - Parameters:
    ///   - name: Name of the contact (person or department)
    ///   - email: Email address for contact
    ///   - website: Website URL
    ///   - phone: Phone number for contact
    ///   - address: Physical address
    ///   - socialMediaHandles: Dictionary of platform names and handles
    public init(
        name: String? = nil,
        email: String? = nil,
        website: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        socialMediaHandles: [String: String]? = [:]
    ) {
        self.name = name
        self.email = email
        self.website = website
        self.phone = phone
        self.address = address
        self.socialMediaHandles = socialMediaHandles
    }
}
