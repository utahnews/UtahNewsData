import Foundation

public extension MediaItem {
    var urlValue: URL? { URL(string: url) }
    var fileType: String { (url as NSString).pathExtension }
    var documentURL: URL { URL(fileURLWithPath: url) }
    var credit: String? { metadata["credit"] }
} 