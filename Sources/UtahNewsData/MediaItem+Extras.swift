import Foundation
import UtahNewsDataModels

public extension MediaItem {
    public var urlValue: URL? { URL(string: url) }
    public var fileType: String { (url as NSString).pathExtension }
    public var documentURL: URL { URL(fileURLWithPath: url) }
    public var credit: String? { metadata["credit"] }
} 