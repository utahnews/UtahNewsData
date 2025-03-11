//
//  JSONSchemaProvider.swift
//  UtahNewsData
//
//  Created by Mark Evans on 03/11/25
//
//  Summary: Defines a protocol for types that provide a JSON schema for instructing an LLM
//           how to respond with JSON. Each conforming type supplies a static JSON schema.

import Foundation

public protocol JSONSchemaProvider {
    /// A static JSON schema as a String.
    static var jsonSchema: String { get }
}
