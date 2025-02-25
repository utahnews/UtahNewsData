/*
 # UtahNewsData Package
 
 This is the main entry point for the UtahNewsData package, which provides a comprehensive
 set of data models and utilities for working with news data specific to Utah.
 
 ## Package Overview
 
 UtahNewsData is designed to support applications that collect, process, and display
 news content from various sources throughout Utah. It provides:
 
 1. Core data models for news entities (articles, videos, audio)
 2. Entity models for people, organizations, locations, and other news-related concepts
 3. Relationship tracking between entities
 4. Utilities for data processing and retrieval
 5. Support for RAG (Retrieval Augmented Generation) systems
 
 ## Key Components
 
 - News Content Models: Article, Video, Audio
 - Entity Models: Person, Organization, Location, etc.
 - Relationship System: AssociatedData protocol and Relationship struct
 - Data Processing: ScrapeStory and related models
 - Utilities: Extensions, RAG utilities
 
 ## Usage
 
 Import this package into your Swift project to access the full range of models and utilities:
 
 ```swift
 import UtahNewsData
 
 // Create and use news content
 let article = Article(
     title: "Utah Legislature Passes New Bill",
     url: "https://example.com/utah-legislature-bill",
     textContent: "The Utah Legislature today passed a bill that..."
 )
 
 // Work with entities and relationships
 let person = Person(name: "Jane Doe", details: "State Senator")
 let organization = Organization(name: "Utah State Legislature")
 
 // Create relationships between entities
 let relationship = Relationship(
     id: organization.id,
     type: .organization,
     displayName: "Member of"
 )
 person.relationships.append(relationship)
 ```
 
 For more detailed examples, see the documentation for individual components.
 */

// The Swift Programming Language
// https://docs.swift.org/swift-book
