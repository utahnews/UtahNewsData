//
//  JSONSchemaProvider.swift
//  UtahNewsDataModels
//
//  Created by Mark Evans on 01/29/25
//
//  Summary: Defines a protocol for types that provide a JSON schema for instructing an LLM
//           how to respond with JSON. Each conforming type supplies a static JSON schema.

import Foundation

/// A protocol for types that provide JSON schema definitions.
/// This is used to instruct LLMs on how to format their responses as structured JSON.
public protocol JSONSchemaProvider {
    /// A static JSON schema as a String that defines the structure for this type.
    /// The schema should follow JSON Schema specification format.
    static var jsonSchema: String { get }
}