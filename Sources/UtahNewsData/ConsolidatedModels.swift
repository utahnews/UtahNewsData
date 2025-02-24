// This file consolidates model definitions (commented out) from targeted files.
// Generated on Sun Feb 23 17:53:43 MST 2025
// Current time: February 4, 2025 at 1:58:27 PM MST
// Do NOT uncomment this file into your code base.

// File: Article.swift
// //
// //  Article.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 11/18/24.
// //
// 
// import SwiftUI
// import Foundation
// 
// /// A struct representing an article in the news app.
// public struct Article: NewsContent, Identifiable {
//     public var id: UUID
//     public var title: String
//     public var url: String
//     public var urlToImage: String?
//     public var additionalImages: [String]?
//     public var publishedAt: Date
//     public var textContent: String?
//     public var author: String?
//     public var category: String?
//     public var videoURL: String?
//     public var location: Location?
//     // public var sourceTrace: SourceTrace?
//     
// 
//     
//    public init?(from scrapeStory: ScrapeStory, baseURL: String?) {
//        self.id = UUID()
// 
//        guard let title = scrapeStory.title, !title.isEmpty else {
//            print("Invalid title in ScrapeStory: \(scrapeStory)")
//            return nil
//        }
//        self.title = title
// 
//        if let urlString = scrapeStory.url, !urlString.isEmpty {
//            if let validURLString = urlString.constructValidURL(baseURL: baseURL) {
//                self.url = validURLString
//            } else {
//                print("Invalid URL in ScrapeStory: \(scrapeStory)")
//                return nil
//            }
//        } else {
//            print("Missing URL in ScrapeStory: \(scrapeStory)")
//            return nil
//        }
// 
//        self.urlToImage = scrapeStory.urlToImage?.constructValidURL(baseURL: baseURL)
//        self.textContent = scrapeStory.textContent
//        self.author = scrapeStory.author
//        self.category = scrapeStory.category
//        self.videoURL = scrapeStory.videoURL?.constructValidURL(baseURL: baseURL)
// 
//        // Parse date
//        if let publishedAtString = scrapeStory.publishedAt {
//            let isoFormatter = ISO8601DateFormatter()
//            if let date = isoFormatter.date(from: publishedAtString) {
//                self.publishedAt = date
//            } else {
//                print("Invalid date format in ScrapeStory: \(scrapeStory)")
//                self.publishedAt = Date()
//            }
//        } else {
//            self.publishedAt = Date()
//        }
//    }
// }
// 
// public extension Article {
//     init(
//         id: UUID = UUID(),
//         title: String,
//         url: String,
//         urlToImage: String? = "https://picsum.photos/800/1200",
//         publishedAt: Date = Date(),
//         textContent: String? = nil,
//         author: String? = nil,
//         category: String? = nil,
//         location: Location? = nil
//     ) {
//         self.id = id
//         self.title = title
//         self.url = url
//         self.urlToImage = urlToImage
//         self.publishedAt = publishedAt
//         self.textContent = textContent
//         self.author = author
//         self.category = category
//         self.location = location
//     }
// }
// 
// public extension Article {
//     /// An example instance of `Article` for previews and testing.
//     @MainActor static let example = Article(
//         title: "Utah News App Launches Today: Get the Latest News, Sports, and Weather",
//         url: "https://www.utahnews.com",
//         urlToImage: "https://picsum.photos/800/1200",
//         textContent: """
//         Utah News is a news app for Utah. Get the latest news, sports, and weather from Utah News. Stay informed about local events and stories that matter to you.
//         """,
//         author: "Mark Evans",
//         category: "News"
//     )
// }
// 
// 
// 
// public struct MapResponse: Codable {
//     public let success: Bool
//     public let links: [String]
// }
// 

// File: AssociatedData.swift
// //
// //  AssociatedData.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 11/26/24.
// //
// 
// import Foundation
// 
// 
// import SwiftUI
// import Foundation
// 
// public protocol AssociatedData {
//     var id: String { get }
//     var relationships: [Relationship] { get set }
// }
// 
// public struct Relationship: Codable, Hashable {
//     public let id: String
//     public let type: AssociatedDataType
//     public var displayName: String?
//     
//     public init(id: String, type: AssociatedDataType, displayName: String?) {
//         self.id = id
//         self.type = type
//         self.displayName = displayName
//     }
// }
// 
// public enum AssociatedDataType: String, Codable {
//     case person = "persons"
//     case organization = "organizations"
//     case location = "locations"
//     case category = "categories"
//     case source = "sources"
//     case mediaItem = "mediaItems"
//     case newsEvent = "newsEvents"
//     case newsStory = "newsStories"
//     case quote = "quotes"
//     case fact = "facts"
//     case statisticalData = "statisticalData"
//     case calendarEvent = "calendarEvents"
//     case legalDocument = "legalDocuments"
//     case socialMediaPost = "socialMediaPosts"
//     case expertAnalysis = "expertAnalyses"
//     case poll = "polls"
//     case alert = "alerts"
//     // Add other types as needed
// }
// 

// File: Audio.swift
// //
// //  Audio.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 11/18/24.
// //
// 
// import Foundation
// 
// /// A struct representing an audio clip in the news app.
// public struct Audio: NewsContent {
//     public var id: UUID
//     public var title: String
//     public var url: String
//     public var urlToImage: String?
//     public var publishedAt: Date
//     public var textContent: String?
//     public var author: String?
//     public var duration: TimeInterval
//     public var bitrate: Int
//     
//     public init(
//         id: UUID = UUID(),
//         title: String,
//         url: String,
//         urlToImage: String? = "https://picsum.photos/800/1200",
//         publishedAt: Date = Date(),
//         textContent: String? = nil,
//         author: String? = nil,
//         duration: TimeInterval,
//         bitrate: Int
//     ) {
//         self.id = id
//         self.title = title
//         self.url = url
//         self.urlToImage = urlToImage
//         self.publishedAt = publishedAt
//         self.textContent = textContent
//         self.author = author
//         self.duration = duration
//         self.bitrate = bitrate
//     }
// }
// 
// public extension Audio {
//     /// An example instance of `Audio` for previews and testing.
//     @MainActor static let example = Audio(
//         title: "Utah News Podcast Episode 1",
//         url: "https://www.utahnews.com/podcast-episode-1",
//         urlToImage: "https://picsum.photos/800/600",
//         textContent: "Listen to the first episode of the Utah News podcast.",
//         author: "Mark Evans",
//         duration: 1800, // Duration in seconds
//         bitrate: 256   // Bitrate in kbps
//     )
// }

// File: CalEvent.swift
// //
// //  CalEvent.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// 
// public struct CalEvent: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var title: String
//     public var description: String?
//     public var startDate: Date
//     public var endDate: Date?
// 
//     init(id: String = UUID().uuidString, title: String, startDate: Date) {
//         self.id = id
//         self.title = title
//         self.startDate = startDate
//     }
// }

// File: Category.swift
// //
// //  Category.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// 
// import SwiftUI
// 
// 
// 
// public struct Category: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var name: String
// 
//     init(id: String = UUID().uuidString, name: String) {
//         self.id = id
//         self.name = name
//     }
// }

// File: ExpertAnalysis.swift
// //
// //  ExpertAnalysis.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// 
// public struct ExpertAnalysis: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var expert: Person
//     public var date: Date
//     public var topics: [Category] = []
//     public var credentials: [Credential] = []
// 
//     init(id: String = UUID().uuidString, expert: Person, date: Date) {
//         self.id = id
//         self.expert = expert
//         self.date = date
//     }
// }
// 
// public enum Credential: String {
//     // Academic Degrees
//     case PhD = "Doctor of Philosophy"
//     case MD = "Doctor of Medicine"
//     case JD = "Juris Doctor"
//     case DDS = "Doctor of Dental Surgery"
//     case DVM = "Doctor of Veterinary Medicine"
//     case MS = "Master of Science"
//     case MA = "Master of Arts"
//     case MBA = "Master of Business Administration"
//     case BS = "Bachelor of Science"
//     case BA = "Bachelor of Arts"
//     case BBA = "Bachelor of Business Administration"
//     case BEng = "Bachelor of Engineering"
//     case BFA = "Bachelor of Fine Arts"
//     case BCom = "Bachelor of Commerce"
//     case BArch = "Bachelor of Architecture"
//     case BBA_Marketing = "Bachelor of Business Administration in Marketing"
//     case BBA_Finance = "Bachelor of Business Administration in Finance"
//     
//     // Professional Certifications
//     case CPA = "Certified Public Accountant"
//     case CFA = "Chartered Financial Analyst"
//     case PMP = "Project Management Professional"
//     case CISM = "Certified Information Security Manager"
//     case CISSP = "Certified Information Systems Security Professional"
//     case CISA = "Certified Information Systems Auditor"
//     case CCSP = "Certified Cloud Security Professional"
//     case CEH = "Certified Ethical Hacker"
//     case CCNA = "Cisco Certified Network Associate"
//     case CCNP = "Cisco Certified Network Professional"
//     case AWS_SA = "AWS Certified Solutions Architect"
//     case AWS_DevOps = "AWS Certified DevOps Engineer"
//     case GCA = "Google Cloud Professional Cloud Architect"
//     case AZ_Admin = "Microsoft Certified: Azure Administrator Associate"
//     case ITIL = "Information Technology Infrastructure Library"
//     case SHRM_CP = "Society for Human Resource Management Certified Professional"
//     case SHRM_SCP = "Society for Human Resource Management Senior Certified Professional"
//     case LSSBB = "Lean Six Sigma Black Belt"
//     case LSSGB = "Lean Six Sigma Green Belt"
//     case PRINCE2 = "PRINCE2 Practitioner"
//     case TOGAF = "The Open Group Architecture Framework"
//     
//     // Scrum Certifications
//     case CSM = "Certified ScrumMaster (CSM)"
//     case CSPO = "Certified Scrum Product Owner"
//     
//     // Information Technology
//     case CompTIA_A = "CompTIA A+"
//     case CompTIA_Network = "CompTIA Network+"
//     case CompTIA_Security = "CompTIA Security+"
//     case CCIE = "Cisco Certified Internetwork Expert"
//     case Microsoft_Solutions_Expert = "Microsoft Certified: Solutions Expert"
//     case Oracle_Professional = "Oracle Certified Professional"
//     case RHCE = "Red Hat Certified Engineer"
//     case CKA = "Certified Kubernetes Administrator"
//     case CAI_E = "Certified Artificial Intelligence Engineer"
//     case CDS = "Certified Data Scientist"
//     case CMLP = "Certified Machine Learning Professional"
//     case CBlockchain_Dev = "Certified Blockchain Developer"
//     case CVirtualization_Prof = "Certified Virtualization Professional"
//     case CIoT_Specialist = "Certified Internet of Things Specialist"
//     
//     // Healthcare Certifications
//     case RN = "Registered Nurse"
//     case NP = "Nurse Practitioner"
//     case CRNA = "Certified Registered Nurse Anesthetist"
//     case DNP = "Doctor of Nursing Practice"
//     case CPHQ = "Certified Professional in Healthcare Quality"
//     case CHC = "Certified in Healthcare Compliance"
//     case CPM = "Certified Project Manager"
//     case CCC = "Certificate of Clinical Competence"
//     
//     // Finance and Accounting
//     case CPA_CGMA = "Certified Public Accountant - Chartered Global Management Accountant"
//     case CFE = "Certified Fraud Examiner"
//     case CMA = "Certified Management Accountant"
//     case CFP = "Certified Financial Planner"
//     case FRM = "Financial Risk Manager"
//     case CAIA = "Chartered Alternative Investment Analyst"
//     case CFA_I = "Chartered Financial Analyst Level I"
//     case CFA_II = "Chartered Financial Analyst Level II"
//     case CFA_III = "Chartered Financial Analyst Level III"
//     
//     // Marketing and Sales
//     case CMO = "Chief Marketing Officer Certification"
//     case CSMM = "Certified Social Media Marketing"
//     case CSEO = "Certified SEO Professional"
//     case CPPM = "Certified Product Marketing Manager"
//     case CPIM = "Certified Product Information Manager"
//     case CSEM = "Certified Sales and Marketing Professional"
//     
//     // Human Resources
//     case PHR = "Professional in Human Resources"
//     case SPHR = "Senior Professional in Human Resources"
//     case GPHR = "Global Professional in Human Resources"
//     case aPHR = "Associate Professional in Human Resources"
//     
//     // Legal Certifications
//     case LLM = "Master of Law"
//     case BCL = "Bachelor of Civil Law"
//     case JD_Specialization = "Juris Doctor - Specialization"
//     
//     // Engineering Certifications
//     case PE = "Professional Engineer"
//     case CEng = "Chartered Engineer"
//     case CPEng = "Certified Professional Engineer"
//     
//     // Additional Certifications
//     case CMC = "Certified Management Consultant"
//     case ASQ_CQE = "Certified Quality Engineer"
//     case CSD = "Chartered Scientist"
//     case MRICS = "Member of the Royal Institution of Chartered Surveyors"
//     case IFSP = "International Fire Safety Professional"
//     case CFRE = "Certified Fund Raising Executive"
//     case CTP = "Certified Treasury Professional"
//     case APICS = "Certified in Planning and Inventory Management"
//     case CCEP = "Certified Compliance and Ethics Professional"
//     case CPP = "Certified Protection Professional"
//     case AICPA = "American Institute of Certified Public Accountants"
//     
//     // Emerging and Specialized Fields
//     case CDMP = "Certified Digital Marketing Professional"
//     case CSM_Manager = "Certified Social Media Manager"
//     case CCM = "Certified Content Marketer"
//     case CPP_Specialist = "Certified Pay-Per-Click Specialist"
//     case CEMP = "Certified Email Marketing Specialist"
//     case CGAS = "Certified Google Ads Specialist"
//     case CFAS = "Certified Facebook Ads Specialist"
//     case CTAS = "Certified Twitter Ads Specialist"
//     case CLAS = "Certified LinkedIn Ads Specialist"
//     case CIM_Specialist = "Certified Instagram Marketing Specialist"
//     case CYM_Specialist = "Certified YouTube Marketing Specialist"
//     case CTM_Specialist = "Certified TikTok Marketing Specialist"
//     case CSL_Admin = "Certified Slack Administrator"
//     case CZoom_Admin = "Certified Zoom Administrator"
//     case CMC365_Admin = "Certified Microsoft 365 Administrator"
//     case CGWS_Admin = "Certified Google Workspace Administrator"
//     case CAWS_Admin = "Certified Amazon Web Services Administrator"
//     case CIBM_Cloud_Prof = "Certified IBM Cloud Professional"
//     case CSAP_HANA_Prof = "Certified SAP HANA Professional"
//     
//     // Research and Academia
//     case CRA = "Clinical Research Associate"
//     case CCRA = "Certified Clinical Research Associate"
//     case CAPM = "Certified Associate in Project Management"
//     case PgMP = "Program Management Professional"
//     
//     // Miscellaneous
//     case CLC = "Certified Life Coach"
//     case CLU = "Chartered Life Underwriter"
//     case CHRL = "Certified Human Resources Leader"
//     case SANS = "Security Awareness Training"
//     case DPO = "Data Protection Officer"
// }

// File: Extensions.swift
// //
// //  File.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 11/26/24.
// //
// 
// import Foundation
// 
// 
// 
// extension String {
//     /// Constructs a fully qualified URL using the base URL if needed.
//     /// - Parameter baseURL: The base URL to use if the URL string is relative.
//     /// - Returns: A fully qualified URL string if valid, else `nil`.
//     func constructValidURL(baseURL: String?) -> String? {
//         if let url = URL(string: self), url.scheme != nil, url.host != nil {
//             return self
//         }
//         if let baseURL = baseURL, let base = URL(string: baseURL) {
//             if let fullURL = URL(string: self, relativeTo: base)?.absoluteURL {
//                 return fullURL.absoluteString
//             }
//         }
//         return nil
//     }
// }

// File: Fact.swift
// //
// //  Fact.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// public struct Fact: AssociatedData, Codable {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var statement: String
//     public var dateVerified: Date?  // Made optional to handle empty date strings
// 
//     // Default initializer
//     public init(
//         id: String = UUID().uuidString,
//         statement: String,
//         dateVerified: Date? = nil
//     ) {
//         self.id = id
//         self.statement = statement
//         self.dateVerified = dateVerified
//     }
//     
//     // Custom initializer to supply a default id if missing
//     // and to decode the dateVerified string, setting it to nil if empty.
//     public init(from decoder: Decoder) throws {
//         let container = try decoder.container(keyedBy: CodingKeys.self)
//         self.statement = try container.decode(String.self, forKey: .statement)
//         
//         // Decode the date string and convert it to a Date.
//         let dateString = try container.decode(String.self, forKey: .dateVerified)
//         if dateString.isEmpty {
//             self.dateVerified = nil
//         } else {
//             let formatter = ISO8601DateFormatter()
//             self.dateVerified = formatter.date(from: dateString)
//         }
//         
//         self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
//         self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
//     }
//     
//     // Standard encoding implementation.
//     public func encode(to encoder: Encoder) throws {
//         var container = encoder.container(keyedBy: CodingKeys.self)
//         try container.encode(id, forKey: .id)
//         try container.encode(relationships, forKey: .relationships)
//         try container.encode(statement, forKey: .statement)
//         
//         // When encoding, if dateVerified is not nil, encode it as an ISO8601 string; otherwise encode an empty string.
//         if let date = dateVerified {
//             let formatter = ISO8601DateFormatter()
//             let dateString = formatter.string(from: date)
//             try container.encode(dateString, forKey: .dateVerified)
//         } else {
//             try container.encode("", forKey: .dateVerified)
//         }
//     }
//     
//     enum CodingKeys: String, CodingKey {
//         case id
//         case relationships
//         case statement
//         case dateVerified
//     }
// }
// 
// public enum Verification: String, CaseIterable {
//     case none = "None"
//     case human = "Human"
//     case ai = "AI"
// }

// File: Jurisdiction.swift
// //
// //  File.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 12/10/24.
// //
// 
// import SwiftUI
// 
// 
// public enum JurisdictionType: String, Codable, CaseIterable {
//     case city
//     case county
//     case state
// 
//     public var label: String {
//         switch self {
//         case .city: return "City"
//         case .county: return "County"
//         case .state: return "State"
//         }
//     }
// }
// 
// 
// // If a previously location-less Jurisdiction now includes a location (or vice versa),
// // decoding might fail if the structure of the Firestore document differs from what
// // the Codable synthesis expects. For example, Firestore might omit the "location" field entirely
// // if there is no location set, or it could store partial data that doesn't map cleanly.
// //
// // To fix this, you can make the decoding of `location` more resilient. Since location is optional,
// // you can use `decodeIfPresent` so that if location data is missing or malformed, `location` will
// // simply be nil rather than causing a decoding error.
// //
// // Here's how you can update your Jurisdiction object definition to safely handle both cases:
// // Jurisdictions with and without Locations will decode properly.
// //
// // In your Jurisdiction definition, add CodingKeys and a custom initializer to decode
// // `location` using `try?` or `decodeIfPresent`:
// 
// public struct Jurisdiction: AssociatedData, Identifiable, Codable {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var type: JurisdictionType
//     public var name: String
//     public var location: Location?   // This remains optional
//     public var website: String?
// 
//     // Existing initializer
//     public init(id: String = UUID().uuidString, type: JurisdictionType, name: String, location: Location? = nil) {
//         self.id = id
//         self.type = type
//         self.name = name
//         self.location = location
//     }
// 
//     // Add CodingKeys to handle decoding more gracefully
//     enum CodingKeys: String, CodingKey {
//         case id
//         case relationships
//         case type
//         case name
//         case location
//         case website
//     }
// 
//     // Implement a custom init(from:) to safely decode the optional location
//     public init(from decoder: Decoder) throws {
//         let container = try decoder.container(keyedBy: CodingKeys.self)
// 
//         self.id = try container.decode(String.self, forKey: .id)
//         self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
//         self.type = try container.decode(JurisdictionType.self, forKey: .type)
//         self.name = try container.decode(String.self, forKey: .name)
//         // Use decodeIfPresent for location so it's nil if field is missing or can't decode
//         self.location = try? container.decodeIfPresent(Location.self, forKey: .location)
//         self.website = try? container.decodeIfPresent(String.self, forKey: .website)
//     }
// 
//     // The default synthesized encode(to:) should still work fine.
// }

// File: LegalDocument.swift
// //
// //  LegalDocument.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// 
// public struct LegalDocument: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var title: String
//     public var dateIssued: Date
// 
//     init(id: String = UUID().uuidString, title: String, dateIssued: Date) {
//         self.id = id
//         self.title = title
//         self.dateIssued = dateIssued
//     }
// }

// File: Location.swift
// //
// //  Location.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// // Location.swift
// // Summary: Defines the Location structure for the UtahNewsData module.
// //          Now includes a convenience initializer to create a Location with coordinates.
// 
// import SwiftUI
// 
// public struct Location: AssociatedData, Codable, Hashable, Equatable {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var name: String
//     public var address: String?
//     public var coordinates: Coordinates?
//     
//     // Existing initializer
//     public init(id: String = UUID().uuidString, name: String) {
//         self.id = id
//         self.name = name
//     }
//     
//     // New convenience initializer to include coordinates
//     public init(id: String = UUID().uuidString, name: String, coordinates: Coordinates?) {
//         self.id = id
//         self.name = name
//         self.coordinates = coordinates
//     }
// }
// 
// public struct Coordinates: Codable, Hashable, Equatable {
//     public var latitude: Double
//     public var longitude: Double
//     
//     public init(latitude: Double, longitude: Double) {
//         self.latitude = latitude
//         self.longitude = longitude
//     }
// }

// Warning: File Medialtem.swift not found in ./Sources/UtahNewsData
// File: NewsAlert.swift
// //
// //  NewsAlert.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// 
// public struct NewsAlert: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var title: String
//     public var message: String
//     public var dateIssued: Date
//     public var level: AlertLevel
// 
//     init(id: String = UUID().uuidString, title: String, message: String, dateIssued: Date, level: AlertLevel) {
//         self.id = id
//         self.title = title
//         self.message = message
//         self.dateIssued = dateIssued
//         self.level = level
//     }
// }
// 
// public enum AlertLevel {
//     case low
//     case medium
//     case high
//     case critical
// }

// File: NewsContent.swift
// //
// //  NewsContent.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 11/18/24.
// //
// 
// import Foundation
// 
// /// A protocol defining the common properties and methods for news content types.
// public protocol NewsContent: Identifiable, Codable, Equatable, Hashable {
//     var id: UUID { get set }
//     var title: String { get set }
//     var url: String { get set }
//     var urlToImage: String? { get set }
//     var publishedAt: Date { get set }
//     var textContent: String? { get set }
//     var author: String? { get set }
//     
//     func basicInfo() -> String
// }
// 
// public extension NewsContent {
//     func basicInfo() -> String {
//         return "Title: \(title), Published At: \(publishedAt)"
//     }
// }

// File: NewsEvent.swift
// //
// //  NewsEvent.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// 
// 
// public struct NewsEvent: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var title: String
//     public var date: Date
//     public var quotes: [Quote] = []
//     public var facts: [Fact] = []
//     public var statisticalData: [StatisticalData] = []
//     public var categories: [Category] = []
// 
//     init(id: String = UUID().uuidString, title: String, date: Date) {
//         self.id = id
//         self.title = title
//         self.date = date
//     }
// }

// File: NewsStory.swift
// //
// //  NewsStory.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// public struct NewsStory: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var headline: String
//     public var author: Person
//     public var publishedDate: Date
//     public var categories: [Category] = []
//     public var sources: [Source] = []
// 
//     init(id: String = UUID().uuidString, headline: String, author: Person, publishedDate: Date) {
//         self.id = id
//         self.headline = headline
//         self.author = author
//         self.publishedDate = publishedDate
//     }
// }

// File: Organization.swift
// //
// //  Organization.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// public struct Organization: AssociatedData, Codable, Identifiable, Hashable {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var name: String
//     public var orgDescription: String?   // Internal property name
//     public var contactInfo: [ContactInfo]? = []
//     public var website: String?
// 
//     public init(
//         id: String = UUID().uuidString,
//         name: String,
//         orgDescription: String? = nil,
//         contactInfo: [ContactInfo]? = nil,
//         website: String? = nil
//     ) {
//         self.id = id
//         self.name = name
//         self.orgDescription = orgDescription
//         self.contactInfo = contactInfo
//         self.website = website
//     }
//     
//     public init(from decoder: Decoder) throws {
//         let container = try decoder.container(keyedBy: CodingKeys.self)
//         // Use decodeIfPresent for id and fall back to a new UUID if missing.
//         self.id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
//         self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
//         self.name = try container.decode(String.self, forKey: .name)
//         // First try the new key "orgDescription", then fall back to the legacy key "description"
//         let decodedDesc = (try? container.decodeIfPresent(String.self, forKey: .orgDescription))
//             ?? (try? container.decodeIfPresent(String.self, forKey: .oldDescription))
//         self.orgDescription = (decodedDesc?.isEmpty ?? true) ? nil : decodedDesc
//         self.contactInfo = (try? container.decode([ContactInfo].self, forKey: .contactInfo)) ?? []
//         self.website = try? container.decode(String.self, forKey: .website)
//     }
//     
//     public func encode(to encoder: Encoder) throws {
//         var container = encoder.container(keyedBy: CodingKeys.self)
//         try container.encode(id, forKey: .id)
//         try container.encode(relationships, forKey: .relationships)
//         try container.encode(name, forKey: .name)
//         // Always encode using the legacy key "description" for backward compatibility.
//         try container.encode(orgDescription, forKey: .oldDescription)
//         try container.encode(contactInfo, forKey: .contactInfo)
//         try container.encode(website, forKey: .website)
//     }
//     
//     private enum CodingKeys: String, CodingKey {
//         case id, relationships, name
//         case orgDescription
//         case oldDescription = "description"
//         case contactInfo, website
//     }
// }

// File: Person.swift
// //
// //  Person.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on [date].
// //
// //  Updated to include additional properties for public interest/notability.
// 
// import SwiftUI
// 
// public struct Person: AssociatedData, Codable, Identifiable, Hashable {
//     // MARK: - Core Properties
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var name: String
//     public var details: String
// 
//     // MARK: - Additional Public Figure Properties
//     public var biography: String?
//     public var birthDate: Date?
//     public var deathDate: Date?
//     public var occupation: String?
//     public var nationality: String?
//     public var notableAchievements: [String]?
//     public var imageURL: String?
//     public var locationString: String?
//     public var locationLatitude: Double?
//     public var locationLongitude: Double?
//     public var email: String?
//     public var website: String?
//     public var phone: String?
//     public var address: String?
//     public var socialMediaHandles: [String: String]?
// 
//     // MARK: - Initializer
//     public init(
//         id: String = UUID().uuidString,
//         relationships: [Relationship] = [],
//         name: String,
//         details: String,
//         biography: String? = nil,
//         birthDate: Date? = nil,
//         deathDate: Date? = nil,
//         occupation: String? = nil,
//         nationality: String? = nil,
//         notableAchievements: [String]? = nil,
//         imageURL: String? = nil,
//         locationString: String? = nil,
//         locationLatitude: Double? = nil,
//         locationLongitude: Double? = nil,
//         email: String? = nil,
//         website: String? = nil,
//         phone: String? = nil,
//         address: String? = nil,
//         socialMediaHandles: [String: String]? = [:]
//     ) {
//         self.id = id
//         self.relationships = relationships
//         self.name = name
//         self.details = details
// 
//         self.biography = biography
//         self.birthDate = birthDate
//         self.deathDate = deathDate
//         self.occupation = occupation
//         self.nationality = nationality
//         self.notableAchievements = notableAchievements
// 
//         self.imageURL = imageURL
//         self.locationString = locationString
//         self.locationLatitude = locationLatitude
//         self.locationLongitude = locationLongitude
//         self.email = email
//         self.website = website
//         self.phone = phone
//         self.address = address
//         self.socialMediaHandles = socialMediaHandles
//     }
//     
//     // MARK: - Decodable
//     public init(from decoder: Decoder) throws {
//         let container = try decoder.container(keyedBy: CodingKeys.self)
//         self.name = try container.decode(String.self, forKey: .name)
//         self.details = try container.decode(String.self, forKey: .details)
//         self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
//         self.relationships = (try? container.decode([Relationship].self, forKey: .relationships)) ?? []
//         
//         self.biography = try? container.decode(String.self, forKey: .biography)
//         self.birthDate = try? container.decode(Date.self, forKey: .birthDate)
//         self.deathDate = try? container.decode(Date.self, forKey: .deathDate)
//         self.occupation = try? container.decode(String.self, forKey: .occupation)
//         self.nationality = try? container.decode(String.self, forKey: .nationality)
//         self.notableAchievements = try? container.decode([String].self, forKey: .notableAchievements)
// 
//         // New properties decoding
//         self.imageURL = try? container.decode(String.self, forKey: .imageURL)
//         self.locationString = try? container.decode(String.self, forKey: .locationString)
//         self.locationLatitude = try? container.decode(Double.self, forKey: .locationLatitude)
//         self.locationLongitude = try? container.decode(Double.self, forKey: .locationLongitude)
//         self.email = try? container.decode(String.self, forKey: .email)
//         self.website = try? container.decode(String.self, forKey: .website)
//         self.phone = try? container.decode(String.self, forKey: .phone)
//         self.address = try? container.decode(String.self, forKey: .address)
//         self.socialMediaHandles = try? container.decode([String: String].self, forKey: .socialMediaHandles)
//     }
//     
//     // MARK: - Encodable
//     public func encode(to encoder: Encoder) throws {
//         var container = encoder.container(keyedBy: CodingKeys.self)
//         try container.encode(id, forKey: .id)
//         try container.encode(relationships, forKey: .relationships)
//         try container.encode(name, forKey: .name)
//         try container.encode(details, forKey: .details)
//         
//         try container.encode(biography, forKey: .biography)
//         try container.encode(birthDate, forKey: .birthDate)
//         try container.encode(deathDate, forKey: .deathDate)
//         try container.encode(occupation, forKey: .occupation)
//         try container.encode(nationality, forKey: .nationality)
//         try container.encode(notableAchievements, forKey: .notableAchievements)
//         
//         // New properties encoding
//         try container.encode(imageURL, forKey: .imageURL)
//         try container.encode(locationString, forKey: .locationString)
//         try container.encode(locationLatitude, forKey: .locationLatitude)
//         try container.encode(locationLongitude, forKey: .locationLongitude)
//         try container.encode(email, forKey: .email)
//         try container.encode(website, forKey: .website)
//         try container.encode(phone, forKey: .phone)
//         try container.encode(address, forKey: .address)
//         try container.encode(socialMediaHandles, forKey: .socialMediaHandles)
//     }
//     
//     // MARK: - Coding Keys
//     enum CodingKeys: String, CodingKey {
//         case id, relationships, name, details
//         case biography, birthDate, deathDate, occupation, nationality, notableAchievements
//         // New keys added
//         case imageURL, locationString, locationLatitude, locationLongitude, email, website, phone, address, socialMediaHandles
//     }
// }

// File: Poll.swift
// //
// //  Poll.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// 
// public struct Poll: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var question: String
//     public var options: [String]
//     public var responses: [PollResponse] = []
//     public var dateConducted: Date
//     public var source: Source
// 
//     init(id: String = UUID().uuidString, question: String, options: [String], dateConducted: Date, source: Source) {
//         self.id = id
//         self.question = question
//         self.options = options
//         self.dateConducted = dateConducted
//         self.source = source
//     }
// }
// 
// public struct PollResponse {
//     public var respondent: Person?
//     public var selectedOption: String
// }

// File: Quote.swift
// //
// //  Quote.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// 
// public struct Quote: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var author: Person
//     public var date: Date?
// 
//     init(id: String = UUID().uuidString, author: Person, date: Date? = nil) {
//         self.id = id
//         self.author = author
//         self.date = date
//     }
// }

// File: ScrapeStory.swift
// //
// //  File.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 11/26/24.
// //
// 
// import Foundation
// 
// 
// // MARK: - StoryExtract
// public struct StoryExtract: Codable {
//     public let stories: [ScrapeStory]
// }
// 
// // MARK: - ScrapeStory
// public struct ScrapeStory: Codable, Sendable {
// //    var id: String
//     public var title: String?
//     public var textContent: String?
//     public var url: String?
//     public var urlToImage: String?
//     public var additionalImages: [String]?
//     public var publishedAt: String?
//     public var author: String?
//     public var category: String?
//     public var videoURL: String?
// }
// 
// 
// public struct SingleStoryResponse: Codable {
//     public let success: Bool
//     public let data: SingleStoryData
// }
// 
// // MARK: - SingleStoryData
// public struct SingleStoryData: Codable {
//     public let extract: ScrapeStory
// }
// 
// 
// // MARK: - FirecrawlResponse
// public struct FirecrawlResponse: Codable {
//     public let success: Bool
//     public let data: FirecrawlData
// }
// 
// // MARK: - FirecrawlData
// public struct FirecrawlData: Codable {
//     public let extract: StoryExtract
// }

// File: SocialMediaPost.swift
// //
// //  SocialMediaPost.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// 
// public struct SocialMediaPost: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var author: Person
//     public var platform: String
//     public var datePosted: Date
//     public var url: URL?
// 
//     init(id: String = UUID().uuidString, author: Person, platform: String, datePosted: Date) {
//         self.id = id
//         self.author = author
//         self.platform = platform
//         self.datePosted = datePosted
//     }
// }

// File: Source.swift
// //
// //  Source.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// 
// // By aligning the Source struct with the schema defined in NewsSource, you can decode
// // Firestore documents that match the NewsSource structure directly into Source.
// // This involves changing Source's properties (e.g., using a String for the id instead
// // of UUID, and adding category, subCategory, description, JSONSchema, etc.) so that
// // they match what's stored in your Firestore "sources" collection.
// 
// public struct Source: AssociatedData, Codable, Identifiable, Hashable, Equatable { // Adding Identifiable for convenience
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var name: String
//     public var url: String
//     public var credibilityRating: Int?
//     public var siteMapURL: URL?
//     public var category: NewsSourceCategory
//     public var subCategory: NewsSourceSubcategory?
//     public var description: String?
//     public var JSONSchema: JSONSchema?
// 
//     // If needed, a custom initializer to create a Source from a NewsSource instance:
// //    public init(
// //        newsSource: NewsSource,
// //        credibilityRating: Int? = nil,
// //        relationships: [Relationship] = []
// //    ) {
// //        self.id = newsSource.id
// //        self.name = newsSource.name
// //        self.url = newsSource.url
// //        self.category = newsSource.category
// //        self.subCategory = newsSource.subCategory
// //        self.description = newsSource.description
// //        self.JSONSchema = newsSource.JSONSchema
// //        self.siteMapURL = newsSource.siteMapURL
// //        self.credibilityRating = credibilityRating
// //        self.relationships = relationships
// //    }
// 
//     // If you do not have a direct use for the old initializer, you can remove it,
//     // or provide a default one that suits your Firestore decode scenario.
//     public init(
//         id: String = UUID().uuidString,
//         name: String,
//         url: String,
//         category: NewsSourceCategory = .general,
//         subCategory: NewsSourceSubcategory? = nil,
//         description: String? = nil,
//         JSONSchema: JSONSchema? = nil,
//         siteMapURL: URL? = nil,
//         credibilityRating: Int? = nil,
//         relationships: [Relationship] = []
//     ) {
//         self.id = id
//         self.name = name
//         self.url = url
//         self.category = category
//         self.subCategory = subCategory
//         self.description = description
//         self.JSONSchema = JSONSchema
//         self.siteMapURL = siteMapURL
//         self.credibilityRating = credibilityRating
//         self.relationships = relationships
//     }
// }
// 
// 
// 
// public enum JSONSchema: String, CaseIterable, Codable {
//     case schema1
//     case schema2
//     // Add more schemas as needed
// 
//    public var label: String {
//         switch self {
//         case .schema1:
//             return "Schema 1"
//         case .schema2:
//             return "Schema 2"
//         }
//     }
// }
// 
// public enum NewsSourceCategory: String, CaseIterable, Codable {
//     case localGovernmentAndPolitics
//     case publicSafety
//     case education
//     case healthcare
//     case transportation
//     case economyAndBusiness
//     case environmentAndSustainability
//     case housing
//     case cultureAndEntertainment
//     case sportsAndRecreation
//     case socialServices
//     case technologyAndInnovation
//     case weatherAndNaturalEvents
//     case infrastructure
//     case communityVoicesAndOpinions
//     case general
//     case newsNoticesEventsAndAnnouncements
//     case religion
// 
//    public var label: String {
//         switch self {
//         case .localGovernmentAndPolitics:
//             return "Local Government and Politics"
//         case .publicSafety:
//             return "Public Safety"
//         case .education:
//             return "Education"
//         case .healthcare:
//             return "Healthcare"
//         case .transportation:
//             return "Transportation"
//         case .economyAndBusiness:
//             return "Economy and Business"
//         case .environmentAndSustainability:
//             return "Environment and Sustainability"
//         case .housing:
//             return "Housing"
//         case .cultureAndEntertainment:
//             return "Culture and Entertainment"
//         case .sportsAndRecreation:
//             return "Sports and Recreation"
//         case .socialServices:
//             return "Social Services"
//         case .technologyAndInnovation:
//             return "Technology and Innovation"
//         case .weatherAndNaturalEvents:
//             return "Weather and Natural Events"
//         case .infrastructure:
//             return "Infrastructure"
//         case .communityVoicesAndOpinions:
//             return "Community Voices and Opinions"
//         case .general:
//             return "General"
//         case .newsNoticesEventsAndAnnouncements:
//             return "News, Notices, Events, and Announcements"
//         case .religion:
//             return "Religion"
//         }
//     }
// }
// 
// public enum NewsSourceSubcategory: String, CaseIterable, Codable {
//     case none
//     case meetings
//     case policies
//     case initiatives
//     case reports
//     case events
// 
//     public var label: String {
//         switch self {
//         case .none:
//             return "None"
//         case .meetings:
//             return "Meetings"
//         case .policies:
//             return "Policies"
//         case .initiatives:
//             return "Initiatives"
//         case .reports:
//             return "Reports"
//         case .events:
//             return "Events"
//         }
//     }
// }
// 
// 
// public struct NewsSource: Codable, Identifiable {
//     public var id: String
//     public var name: String
//     public var url: String
//     public var category: NewsSourceCategory
//     public var subCategory: NewsSourceSubcategory?
//     public var description: String?
//     public var JSONSchema: JSONSchema?
//     public var siteMapURL: URL?
// 
//     init(
//         id: String = UUID().uuidString,
//         name: String = "",
//         url: String = "",
//         category: NewsSourceCategory = .general,
//         subCategory: NewsSourceSubcategory? = nil,
//         description: String? = nil,
//         JSONSchema: JSONSchema? = nil
//     ) {
//         self.id = id
//         self.name = name
//         self.url = url
//         self.category = category
//         self.subCategory = subCategory
//         self.description = description
//         self.JSONSchema = JSONSchema
//     }
// }

// File: StatisticalData.swift
// //
// //  StatisticalData.swift
// //  NewsCapture
// //
// //  Created by Mark Evans on 10/25/24.
// //
// 
// import SwiftUI
// 
// 
// public struct StatisticalData: AssociatedData {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var title: String
//     public var dataPoints: [DataPoint] = []
//     public var source: Source
//     public var date: Date
// 
//     init(id: String = UUID().uuidString, title: String, source: Source, date: Date) {
//         self.id = id
//         self.title = title
//         self.source = source
//         self.date = date
//     }
// }
// 
// public struct DataPoint: Codable {
//     public var label: String
//     public var value: Double
// }

// File: UserSubmission.swift
// //
// //  File.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 1/28/25.
// //
// 
// import Foundation
// 
// 
// public struct UserSubmission: AssociatedData, Codable, Identifiable, Hashable {
//     public var id: String
//     public var relationships: [Relationship] = []
//     public var title: String
//     public var description: String
//     public var dateSubmitted: Date
//     public var user: Person
//     public var text: [TextMedia]
//     public var images: [ImageMedia]
//     public var videos: [VideoMedia]
//     public var audio: [AudioMedia]
//     public var documents: [DocumentMedia]
//     
//     public init(
//         id: String,
//         relationships: [Relationship],
//         title: String,
//         description: String = "",
//         dateSubmitted: Date = Date(),
//         user: Person,
//         text: [TextMedia] = [],
//         images: [ImageMedia] = [],
//         videos: [VideoMedia] = [],
//         audio: [AudioMedia] = [],
//         documents: [DocumentMedia] = []
//     ) {
//         self.id = id
//         self.relationships = relationships
//         self.title = title
//         self.description = description
//         self.dateSubmitted = dateSubmitted
//         self.user = user
//         self.text = text
//         self.images = images
//         self.videos = videos
//         self.audio = audio
//         self.documents = documents
//     }
// }

// File: UtahNewsData.swift
// // The Swift Programming Language
// // https://docs.swift.org/swift-book

// File: Video.swift
// //
// //  Video.swift
// //  UtahNewsData
// //
// //  Created by Mark Evans on 11/18/24.
// //
// 
// import Foundation
// 
// /// A struct representing a video in the news app.
// public struct Video: NewsContent {
//     public var id: UUID
//     public var title: String
//     public var url: String
//     public var urlToImage: String?
//     public var publishedAt: Date
//     public var textContent: String?
//     public var author: String?
//     public var duration: TimeInterval
//     public var resolution: String
//     
//     public init(
//         id: UUID = UUID(),
//         title: String,
//         url: String,
//         urlToImage: String? = "https://picsum.photos/800/1200",
//         publishedAt: Date = Date(),
//         textContent: String? = nil,
//         author: String? = nil,
//         duration: TimeInterval,
//         resolution: String
//     ) {
//         self.id = id
//         self.title = title
//         self.url = url
//         self.urlToImage = urlToImage
//         self.publishedAt = publishedAt
//         self.textContent = textContent
//         self.author = author
//         self.duration = duration
//         self.resolution = resolution
//     }
// }
// 
// public extension Video {
//     /// An example instance of `Video` for previews and testing.
//     @MainActor static let example = Video(
//         title: "Utah News Video Highlights",
//         url: "https://www.utahnews.com/video-highlights",
//         urlToImage: "https://picsum.photos/800/600",
//         textContent: "Watch the latest video highlights from Utah News.",
//         author: "Mark Evans",
//         duration: 300, // Duration in seconds
//         resolution: "1080p"
//     )
// }

