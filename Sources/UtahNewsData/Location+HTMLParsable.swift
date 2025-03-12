import Foundation
import SwiftSoup

extension Location: HTMLParsable {
    public static func parse(from document: Document) throws -> Location {
        let address = try extractAddress(from: document)
        let city = try extractCity(from: document)
        let state = try extractState(from: document)
        let zipCode = try extractZipCode(from: document)
        let country = try extractCountry(from: document)
        let coordinates = try extractCoordinates(from: document)
        
        return Location(
            latitude: coordinates?.latitude,
            longitude: coordinates?.longitude,
            address: address,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country,
            relationships: []
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func extractAddress(from document: Document) throws -> String? {
        let selectors = [
            "[itemprop='streetAddress']",
            ".address-line",
            ".street-address"
        ]
        
        for selector in selectors {
            if let address = try document.select(selector).first()?.text(),
               !address.isEmpty {
                return address
            }
        }
        
        return nil
    }
    
    private static func extractCity(from document: Document) throws -> String? {
        let selectors = [
            "[itemprop='addressLocality']",
            ".city",
            ".locality"
        ]
        
        for selector in selectors {
            if let city = try document.select(selector).first()?.text(),
               !city.isEmpty {
                return city
            }
        }
        
        return nil
    }
    
    private static func extractState(from document: Document) throws -> String? {
        let selectors = [
            "[itemprop='addressRegion']",
            ".state",
            ".region"
        ]
        
        for selector in selectors {
            if let state = try document.select(selector).first()?.text(),
               !state.isEmpty {
                return state
            }
        }
        
        return nil
    }
    
    private static func extractZipCode(from document: Document) throws -> String? {
        let selectors = [
            "[itemprop='postalCode']",
            ".postal-code",
            ".zip"
        ]
        
        for selector in selectors {
            if let zipCode = try document.select(selector).first()?.text(),
               !zipCode.isEmpty {
                return zipCode
            }
        }
        
        return nil
    }
    
    private static func extractCountry(from document: Document) throws -> String? {
        let selectors = [
            "[itemprop='addressCountry']",
            ".country"
        ]
        
        for selector in selectors {
            if let country = try document.select(selector).first()?.text(),
               !country.isEmpty {
                return country
            }
        }
        
        return nil
    }
    
    private static func extractCoordinates(from document: Document) throws -> (latitude: Double, longitude: Double)? {
        let latSelectors = [
            "[itemprop='latitude']",
            "meta[property='place:location:latitude']",
            ".latitude"
        ]
        
        let longSelectors = [
            "[itemprop='longitude']",
            "meta[property='place:location:longitude']",
            ".longitude"
        ]
        
        var latitude: Double?
        var longitude: Double?
        
        for selector in latSelectors {
            if let latStr = try document.select(selector).first()?.attr(selector.contains("meta") ? "content" : "text"),
               let lat = Double(latStr) {
                latitude = lat
                break
            }
        }
        
        for selector in longSelectors {
            if let longStr = try document.select(selector).first()?.attr(selector.contains("meta") ? "content" : "text"),
               let long = Double(longStr) {
                longitude = long
                break
            }
        }
        
        if let lat = latitude, let long = longitude {
            return (latitude: lat, longitude: long)
        }
        
        return nil
    }
} 