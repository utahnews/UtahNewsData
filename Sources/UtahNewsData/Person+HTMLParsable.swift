import Foundation
import SwiftSoup

extension Person: HTMLParsable {
    public static func parse(from document: Document) throws -> Person {
        guard try !document.select("body").isEmpty(),
              try !document.select("head").isEmpty() else {
            throw ParsingError.invalidFormat("Invalid HTML document structure")
        }
        
        // Extract required fields
        let name = try extractName(from: document)
        
        // Extract optional fields
        let title = try extractTitle(from: document)
        let biography = try extractBiography(from: document)
        let affiliations = try extractAffiliations(from: document)
        let education = try extractEducation(from: document)
        let locationString = try extractLocation(from: document)
        let contactInfo = try extractContactInfo(from: document)
        let socialMediaProfiles = try extractSocialMediaProfiles(from: document)
        
        // Create and return the Person
        return Person(
            name: name,
            details: title ?? "",
            biography: biography,
            birthDate: nil,
            deathDate: nil,
            occupation: affiliations?.first?.name,
            nationality: nil,
            notableAchievements: nil,
            imageURL: nil,
            locationString: locationString,
            locationLatitude: nil,
            locationLongitude: nil,
            email: contactInfo?.email,
            website: contactInfo?.website,
            phone: contactInfo?.phone,
            address: nil,
            socialMediaHandles: socialMediaProfiles
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractName(from document: Document) throws -> String {
        let nameSelectors = [
            "[itemprop='name']",
            ".person-name",
            "h1.name",
            "meta[property='profile:first_name']"
        ]
        
        for selector in nameSelectors {
            if selector.contains("meta") {
                if let name = try document.select(selector).first()?.attr("content"),
                   !name.isEmpty {
                    return name
                }
            } else {
                if let name = try document.select(selector).first()?.text(),
                   !name.isEmpty {
                    return name
                }
            }
        }
        
        throw ParsingError.missingRequiredField("name")
    }
    
    private static func extractTitle(from document: Document) throws -> String? {
        let titleSelectors = [
            "[itemprop='jobTitle']",
            ".person-title",
            ".job-title",
            "meta[property='profile:title']"
        ]
        
        for selector in titleSelectors {
            if selector.contains("meta") {
                if let title = try document.select(selector).first()?.attr("content"),
                   !title.isEmpty {
                    return title
                }
            } else {
                if let title = try document.select(selector).first()?.text(),
                   !title.isEmpty {
                    return title
                }
            }
        }
        
        return nil
    }
    
    private static func extractBiography(from document: Document) throws -> String? {
        let bioSelectors = [
            "[itemprop='description']",
            ".biography",
            ".person-bio",
            "meta[property='og:description']"
        ]
        
        for selector in bioSelectors {
            if selector.contains("meta") {
                if let bio = try document.select(selector).first()?.attr("content"),
                   !bio.isEmpty {
                    return bio
                }
            } else {
                if let bio = try document.select(selector).first()?.text(),
                   !bio.isEmpty {
                    return bio
                }
            }
        }
        
        return nil
    }
    
    private static func extractAffiliations(from document: Document) throws -> [Organization]? {
        let affiliationSelectors = [
            "[itemprop='affiliation']",
            ".affiliations li",
            ".organization-list li"
        ]
        
        var affiliations: [Organization] = []
        
        for selector in affiliationSelectors {
            let elements = try document.select(selector)
            for element in elements {
                let name = try element.select("[itemprop='name']").first()?.text()
                let type = try element.select("[itemprop='type']").first()?.text()
                
                if let name = name {
                    let org = Organization(
                        name: name,
                        orgDescription: try element.select("[itemprop='description']").first()?.text(),
                        contactInfo: nil,
                        website: try element.select("[itemprop='url']").first()?.attr("href"),
                        logoURL: nil,
                        location: nil,
                        type: type ?? "Unknown"
                    )
                    affiliations.append(org)
                }
            }
        }
        
        return affiliations.isEmpty ? nil : affiliations
    }
    
    private static func extractEducation(from document: Document) throws -> [Education]? {
        let educationSelectors = [
            "[itemprop='alumniOf']",
            ".education li",
            ".education-history li"
        ]
        
        var educationList: [Education] = []
        
        for selector in educationSelectors {
            let elements = try document.select(selector)
            for element in elements {
                let institution = try element.select("[itemprop='name']").first()?.text() ?? ""
                let degree = try element.select("[itemprop='degree']").first()?.text()
                let field = try element.select("[itemprop='field']").first()?.text()
                let yearStr = try element.select("[itemprop='year']").first()?.text()
                let year = yearStr.flatMap { Int($0) }
                
                if !institution.isEmpty {
                    educationList.append(Education(
                        institution: institution,
                        degree: degree,
                        field: field,
                        year: year
                    ))
                }
            }
        }
        
        return educationList.isEmpty ? nil : educationList
    }
    
    private static func extractLocation(from document: Document) throws -> String? {
        let locationSelectors = [
            "[itemprop='location']",
            ".location",
            "meta[property='profile:location']"
        ]
        
        for selector in locationSelectors {
            if selector.contains("meta") {
                if let location = try document.select(selector).first()?.attr("content"),
                   !location.isEmpty {
                    return location
                }
            } else {
                if let location = try document.select(selector).first()?.text(),
                   !location.isEmpty {
                    return location
                }
            }
        }
        
        return nil
    }
    
    private static func extractContactInfo(from document: Document) throws -> ContactInfo? {
        let contactSelectors = [
            "[itemprop='contactInfo']",
            ".contact-info",
            ".contact-details"
        ]
        
        for selector in contactSelectors {
            if let element = try document.select(selector).first() {
                let email = try element.select("[itemprop='email']").first()?.text()
                let phone = try element.select("[itemprop='telephone']").first()?.text()
                let website = try element.select("[itemprop='url']").first()?.attr("href")
                
                if email != nil || phone != nil || website != nil {
                    return ContactInfo(
                        email: email,
                        website: website,
                        phone: phone
                    )
                }
            }
        }
        
        return nil
    }
    
    private static func extractSocialMediaProfiles(from document: Document) throws -> [String: String]? {
        let profileSelectors = [
            "[itemprop='sameAs']",
            ".social-profiles li",
            ".social-media a"
        ]
        
        var profiles: [String: String] = [:]
        
        for selector in profileSelectors {
            let elements = try document.select(selector)
            for element in elements {
                if let url = try? element.attr("href"),
                   !url.isEmpty {
                    let platform = determinePlatform(from: url)
                    profiles[platform] = url
                }
            }
        }
        
        return profiles.isEmpty ? nil : profiles
    }
    
    private static func determinePlatform(from url: String) -> String {
        if url.contains("twitter.com") || url.contains("x.com") {
            return "Twitter"
        } else if url.contains("facebook.com") {
            return "Facebook"
        } else if url.contains("linkedin.com") {
            return "LinkedIn"
        } else if url.contains("instagram.com") {
            return "Instagram"
        } else {
            return "Other"
        }
    }
} 