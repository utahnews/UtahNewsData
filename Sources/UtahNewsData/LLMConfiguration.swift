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
    
    /// Array of model names for simple tasks (titles, authors, dates, categories)
    /// Each entry represents a model that can be used in parallel
    var simpleTaskModels: [String] { get }
    
    /// Array of model names for complex tasks (main content extraction)
    /// Each entry represents a model that can be used in parallel
    var complexTaskModels: [String] { get }
    
    /// Additional headers required for API calls
    var headers: [String: String] { get }
    
    /// Timeout interval for requests (in seconds)
    var timeoutInterval: TimeInterval { get }
}

/// Standard implementation of LLMConfiguration
public struct StandardLLMConfig: LLMConfiguration {
    public let baseURL: URL
    public let simpleTaskModels: [String]
    public let complexTaskModels: [String]
    public let headers: [String: String]
    public let timeoutInterval: TimeInterval
    
    public init(
        baseURL: URL,
        simpleTaskModels: [String] = ["llama-3.2-3b-instruct", "llama-3.2-3b-instruct:2", "llama-3.2-3b-instruct:3"],
        complexTaskModels: [String] = ["mistral-nemo-instruct-2407", "mistral-nemo-instruct-2407:2", "mistral-nemo-instruct-2407:3"],
        headers: [String: String] = [:],
        timeoutInterval: TimeInterval = 300
    ) {
        self.baseURL = baseURL
        self.simpleTaskModels = simpleTaskModels
        self.complexTaskModels = complexTaskModels
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
    
    /// Current index for simple task model round-robin
    private var currentSimpleModelIndex = 0
    
    /// Current index for complex task model round-robin
    private var currentComplexModelIndex = 0
    
    private init() {}
    
    /// Configure the LLM settings
    /// - Parameter config: The configuration to use
    public func configure(with config: LLMConfiguration) {
        self.configuration = config
        self.currentSimpleModelIndex = 0
        self.currentComplexModelIndex = 0
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
    
    /// Get the next available model name for a given task type
    /// - Parameter isComplexTask: Whether this is a complex task
    /// - Returns: The next available model name
    /// - Throws: ConfigurationError if no models are configured
    public func nextModel(isComplexTask: Bool) throws -> String {
        guard let config = configuration else {
            throw ConfigurationError.notConfigured
        }
        
        if isComplexTask {
            guard !config.complexTaskModels.isEmpty else {
                throw ConfigurationError.invalidModel
            }
            let model = config.complexTaskModels[currentComplexModelIndex]
            currentComplexModelIndex = (currentComplexModelIndex + 1) % config.complexTaskModels.count
            return model
        } else {
            guard !config.simpleTaskModels.isEmpty else {
                throw ConfigurationError.invalidModel
            }
            let model = config.simpleTaskModels[currentSimpleModelIndex]
            currentSimpleModelIndex = (currentSimpleModelIndex + 1) % config.simpleTaskModels.count
            return model
        }
    }
}

/// Configuration-related errors
public enum ConfigurationError: Error {
    case notConfigured
    case invalidURL
    case invalidModel
} 