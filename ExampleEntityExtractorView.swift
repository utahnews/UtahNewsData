import SwiftUI
import UtahNewsData

struct ExampleEntityExtractorView: View {
    @State private var urlInput = ""
    @State private var urls: [String] = []
    @State private var selectedEntityType = EntityType.article
    @State private var isLoading = false
    @State private var extractedContents: [Any] = []
    @State private var errorMessage: String?

    private let entityTypes: [EntityType] = [
        .article,
        .newsStory,
        .person,
        .organization,
        .alert,
        .poll,
        .jurisdiction,
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Input")) {
                    TextField("Enter URL", text: $urlInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.URL)
                        .disableAutocorrection(true)

                    Button("Add URL") {
                        if !urlInput.isEmpty {
                            urls.append(urlInput)
                            urlInput = ""
                        }
                    }
                    .disabled(urlInput.isEmpty)

                    if !urls.isEmpty {
                        Section(header: Text("URLs to Process")) {
                            ForEach(urls, id: \.self) { url in
                                HStack {
                                    Text(url)
                                    Spacer()
                                    Button(action: {
                                        urls.removeAll { $0 == url }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }

                            Button(action: {
                                urls.removeAll()
                            }) {
                                Text("Clear All")
                                    .foregroundColor(.red)
                            }
                        }
                    }

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
                    .disabled(urls.isEmpty || isLoading)
                }

                if let error = errorMessage {
                    Section(header: Text("Error")) {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                if !extractedContents.isEmpty {
                    Section(header: Text("Extracted Content")) {
                        ForEach(Array(extractedContents.enumerated()), id: \.offset) {
                            index, content in
                            VStack(alignment: .leading) {
                                Text("Result \(index + 1)")
                                    .font(.headline)
                                ExtractedContentView(content: content)
                            }
                            .padding(.vertical, 5)

                            if index < extractedContents.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Entity Extractor")
        }
    }

    private func extractContent() {
        let validUrls = urls.compactMap { URL(string: $0) }
        guard !validUrls.isEmpty else {
            errorMessage = "No valid URLs to process"
            return
        }

        isLoading = true
        errorMessage = nil
        extractedContents = []

        Task {
            do {
                let service = ContentExtractionService.shared
                var contents: [Any] = []

                for url in validUrls {
                    switch selectedEntityType {
                    case .article:
                        let articles = try await service.extractContent(from: url, as: Article.self)
                        contents.append(articles)
                    case .newsStory:
                        let stories = try await service.extractContent(
                            from: url, as: NewsStory.self)
                        contents.append(stories)
                    case .person:
                        let html = try await URLSession.shared.data(from: url).0
                        let htmlString = String(data: html, encoding: .utf8) ?? ""
                        let result = try await service.parser.parseCollectionWithFallback(
                            html: htmlString,
                            from: url,
                            as: Person.self
                        )
                        switch result {
                        case .success(let people, _):
                            contents.append(contentsOf: people)
                        case .failure(let error):
                            throw error
                        }
                    case .organization:
                        let orgs = try await service.extractContent(
                            from: url, as: Organization.self)
                        contents.append(orgs)
                    case .alert:
                        let alerts = try await service.extractContent(from: url, as: NewsAlert.self)
                        contents.append(alerts)
                    case .poll:
                        let polls = try await service.extractContent(from: url, as: Poll.self)
                        contents.append(polls)
                    case .jurisdiction:
                        let jurisdictions = try await service.extractContent(
                            from: url, as: Jurisdiction.self)
                        contents.append(jurisdictions)
                    default:
                        throw ParsingError.unsupportedEntityType
                    }
                }

                await MainActor.run {
                    self.extractedContents = contents
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
                Text("Question: \(poll.question)")
                Text("Source: \(poll.source)")
                if let marginOfError = poll.marginOfError {
                    Text("Margin of Error: \(marginOfError)%")
                }
                if let sampleSize = poll.sampleSize {
                    Text("Sample Size: \(sampleSize)")
                }
                if let demographics = poll.demographics {
                    Text("Demographics: \(demographics)")
                }
                if !poll.options.isEmpty {
                    Text("Options:")
                    ForEach(poll.options, id: \.text) { option in
                        Text("- \(option.text) (\(option.votes) votes)")
                    }
                }

            case let jurisdiction as Jurisdiction:
                Text("Name: \(jurisdiction.name)")
                Text("Type: \(jurisdiction.type.label)")
                if let website = jurisdiction.website {
                    Text("Website: \(website)")
                }
                if let location = jurisdiction.location {
                    Text("Location: \(location.name)")
                    if let city = location.city {
                        Text("City: \(city)")
                    }
                    if let state = location.state {
                        Text("State: \(state)")
                    }
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
        case .article: return "Article"
        case .newsStory: return "News Story"
        case .person: return "Person"
        case .organization: return "Organization"
        case .alert: return "News Alert"
        case .poll: return "Poll"
        case .jurisdiction: return "Jurisdiction"
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
