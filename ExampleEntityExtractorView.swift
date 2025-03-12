import SwiftUI
import UtahNewsData

struct ExampleEntityExtractorView: View {
    @State private var urlString = ""
    @State private var selectedEntityType = EntityType.articles
    @State private var isLoading = false
    @State private var extractedContent: Any?
    @State private var errorMessage: String?
    
    private let entityTypes: [EntityType] = [
        .articles,
        .newsStories,
        .persons,
        .organizations,
        .alerts,
        .polls,
        .jurisdictions
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Input")) {
                    TextField("Enter URL", text: $urlString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Picker("Entity Type", selection: $selectedEntityType) {
                        ForEach(entityTypes, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                    
                    Button(action: extractContent) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Extract Content")
                        }
                    }
                    .disabled(urlString.isEmpty || isLoading)
                }
                
                if let error = errorMessage {
                    Section(header: Text("Error")) {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                if let content = extractedContent {
                    Section(header: Text("Extracted Content")) {
                        ExtractedContentView(content: content)
                    }
                }
            }
            .navigationTitle("Entity Extractor")
        }
    }
    
    private func extractContent() {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let service = ContentExtractionService.shared
                let content: Any
                
                switch selectedEntityType {
                case .articles:
                    let article = try await service.extractContent(from: url, as: Article.self)
                    content = article
                case .newsStories:
                    let story = try await service.extractContent(from: url, as: NewsStory.self)
                    content = story
                case .persons:
                    let person = try await service.extractContent(from: url, as: Person.self)
                    content = person
                case .organizations:
                    content = try await service.extractContent(from: url, as: Organization.self)
                case .alerts:
                    let alert = try await service.extractContent(from: url, as: NewsAlert.self)
                    content = alert
                case .polls:
                    content = try await service.extractContent(from: url, as: Poll.self)
                case .jurisdictions:
                    content = try await service.extractContent(from: url, as: Jurisdiction.self)
                default:
                    throw ParsingError.unsupportedEntityType
                }
                
                await MainActor.run {
                    self.extractedContent = content
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// Helper view to display extracted content
struct ExtractedContentView: View {
    let content: Any
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch content {
            case let article as Article:
                Text("Title: \(article.title)")
                if let author = article.author {
                    Text("Author: \(author)")
                }
                if let content = article.textContent {
                    Text("Content: \(content)")
                }
                if let category = article.category {
                    Text("Category: \(category)")
                }
                if let image = article.urlToImage {
                    Text("Featured Image: \(image)")
                }
                
            case let newsStory as NewsStory:
                Text("Headline: \(newsStory.headline)")
                Text("Author: \(newsStory.author.name)")
                if let content = newsStory.content {
                    Text("Content: \(content)")
                }
                if let url = newsStory.url {
                    Text("URL: \(url)")
                }
                if let featuredImage = newsStory.featuredImageURL {
                    Text("Featured Image: \(featuredImage)")
                }
                
            case let person as Person:
                Text("Name: \(person.name)")
                Text("Details: \(person.details)")
                if let bio = person.biography {
                    Text("Biography: \(bio)")
                }
                if let occupation = person.occupation {
                    Text("Occupation: \(occupation)")
                }
                if let nationality = person.nationality {
                    Text("Nationality: \(nationality)")
                }
                if let imageURL = person.imageURL {
                    Text("Image: \(imageURL)")
                }
                
            case let org as Organization:
                Text("Name: \(org.name)")
                if let desc = org.orgDescription {
                    Text("Description: \(desc)")
                }
                if let website = org.website {
                    Text("Website: \(website)")
                }
                
            case let alert as NewsAlert:
                Text("Title: \(alert.title)")
                Text("Content: \(alert.content)")
                Text("Alert Type: \(alert.alertType)")
                Text("Severity: \(alert.severity.rawValue)")
                if let source = alert.source {
                    Text("Source: \(source)")
                }
                
            case let poll as Poll:
                Text("Title: \(poll.title)")
                if let org = poll.organization {
                    Text("Organization: \(org)")
                }
                if let methodology = poll.methodology {
                    Text("Methodology: \(methodology)")
                }
                
            case let jurisdiction as Jurisdiction:
                Text("Name: \(jurisdiction.name)")
                if let desc = jurisdiction.description {
                    Text("Description: \(desc)")
                }
                if let type = jurisdiction.type {
                    Text("Type: \(type)")
                }
                
            default:
                Text("Unsupported content type")
            }
        }
    }
}

// Helper extensions
extension EntityType {
    var displayName: String {
        switch self {
        case .articles: return "Article"
        case .newsStories: return "News Story"
        case .persons: return "Person"
        case .organizations: return "Organization"
        case .alerts: return "News Alert"
        case .polls: return "Poll"
        case .jurisdictions: return "Jurisdiction"
        default: return "Unknown"
        }
    }
}

enum ParsingError: LocalizedError {
    case unsupportedEntityType
    
    var errorDescription: String? {
        switch self {
        case .unsupportedEntityType:
            return "This entity type is not supported for extraction"
        }
    }
}

#Preview {
    ExampleEntityExtractorView()
} 