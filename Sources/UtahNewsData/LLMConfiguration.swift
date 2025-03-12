//
//  LLMConfiguration.swift
//  UtahNewsData
//
//  Created by Mark Evans on 3/21/24
//
//  Summary: Defines the configuration protocol for LLM settings and related types.

import Foundation

/// Protocol defining the configuration requirements for LLM integration
public protocol LLMConfiguration {
    /// The base URL of the LLM server
    var baseURL: URL { get }
    
    /// The model identifier to use
    var model: String { get }
    
    /// Additional headers required for API calls
    var headers: [String: String] { get }
    
    /// Timeout interval for requests (in seconds)
    var timeoutInterval: TimeInterval { get }
}

/// Standard implementation of LLMConfiguration
public struct StandardLLMConfig: LLMConfiguration {
    public let baseURL: URL
    public let model: String
    public let headers: [String: String]
    public let timeoutInterval: TimeInterval
    
    public init(
        baseURL: URL,
        model: String,
        headers: [String: String] = [:],
        timeoutInterval: TimeInterval = 300
    ) {
        self.baseURL = baseURL
        self.model = model
        self.headers = headers
        self.timeoutInterval = timeoutInterval
    }
}

/// Global LLM configuration manager
@MainActor
public class LLMConfigurationManager: @unchecked Sendable {
    /// Shared instance for global access
    public static let shared = LLMConfigurationManager()
    
    /// The current active configuration
    private var configuration: LLMConfiguration?
    
    private init() {}
    
    /// Configure the LLM settings
    /// - Parameter config: The configuration to use
    public func configure(with config: LLMConfiguration) {
        self.configuration = config
    }
    
    /// Get the current configuration
    /// - Returns: The current LLM configuration
    /// - Throws: ConfigurationError if not configured
    public func currentConfig() throws -> LLMConfiguration {
        guard let config = configuration else {
            throw ConfigurationError.notConfigured
        }
        return config
    }
}

/// Configuration-related errors
public enum ConfigurationError: Error {
    case notConfigured
    case invalidURL
    case invalidModel
} 