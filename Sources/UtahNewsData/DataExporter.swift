import Foundation

/*
 # Data Exporter
 
 This file provides utilities for exporting UtahNewsData models to various formats,
 including SQL statements for relational databases and vector records for embedding.
 
 ## Key Components:
 
 1. Relational Database Export: Generate SQL statements for entities and relationships
 2. Vector Storage Export: Create vector records for embedding in vector databases
 
 ## Usage:
 
 The DataExporter class provides static methods that can be used with any entity
 that implements the AssociatedData protocol:
 
 ```swift
 // Export an entity to SQL
 let personSQL = DataExporter.exportEntityToSQL(person)
 
 // Export relationships to SQL
 let relationshipSQL = DataExporter.exportRelationshipsToSQL(person)
 
 // Generate a vector record for an entity
 let vectorRecord = DataExporter.generateVectorRecord(person)
 ```
 
 These utilities help bridge the gap between the in-memory data model and
 persistent storage systems, enabling efficient data management and retrieval.
 */

/// Utilities for exporting UtahNewsData models to various formats
public class DataExporter {
    
    // MARK: - Relational Database Export
    
    /// Exports an entity to a SQL insert statement.
    /// This generates a parameterized SQL statement that can be used
    /// to insert the entity into a relational database.
    ///
    /// - Parameters:
    ///   - entity: The entity to export
    ///   - tableName: Optional custom table name (defaults to the entity's type name in lowercase)
    /// - Returns: A SQL insert statement with placeholders for values
    ///
    /// - Example:
    ///   ```swift
    ///   let sql = DataExporter.exportEntityToSQL(person)
    ///   // INSERT INTO person (id, name, details, ...) VALUES (:id, :name, :details, ...);
    ///   ```
    public static func exportEntityToSQL<T: AssociatedData & Encodable>(_ entity: T, tableName: String? = nil) -> String {
        let table = tableName ?? String(describing: type(of: entity)).lowercased()
        
        // Convert entity to dictionary, excluding relationships
        var dict = try! entity.asDictionary()
        dict.removeValue(forKey: "relationships")
        
        // Generate column names and values
        let columns = dict.keys.joined(separator: ", ")
        let placeholders = dict.keys.map { ":\($0)" }.joined(separator: ", ")
        
        // Create SQL statement
        return "INSERT INTO \(table) (\(columns)) VALUES (\(placeholders));"
    }
    
    /// Exports relationships to SQL insert statements.
    /// This generates parameterized SQL statements for each relationship
    /// of the entity, suitable for inserting into a relationships table.
    ///
    /// - Parameter entity: The entity whose relationships should be exported
    /// - Returns: An array of SQL insert statements for relationships
    ///
    /// - Example:
    ///   ```swift
    ///   let sqlStatements = DataExporter.exportRelationshipsToSQL(person)
    ///   // [
    ///   //   "INSERT INTO relationships (id, source_id, ...) VALUES (:id, :source_id, ...);",
    ///   //   ...
    ///   // ]
    ///   ```
    public static func exportRelationshipsToSQL<T: AssociatedData>(_ entity: T) -> [String] {
        return entity.relationships.map { relationship -> String in
            let dict: [String: Any] = [
                "id": UUID().uuidString,
                "source_id": entity.id,
                "source_type": String(describing: type(of: entity)).lowercased(),
                "target_id": relationship.id,
                "target_type": relationship.type.rawValue,
                "display_name": relationship.displayName as Any,
                "created_at": relationship.createdAt,
                "context": relationship.context as Any
            ]
            
            // Generate column names and values
            let columns = dict.keys.joined(separator: ", ")
            let placeholders = dict.keys.map { ":\($0)" }.joined(separator: ", ")
            
            // Create SQL statement
            return "INSERT INTO relationships (\(columns)) VALUES (\(placeholders));"
        }
    }
    
    /// Generates CREATE TABLE statements for all entity types.
    /// This creates the SQL schema for storing entities and their relationships.
    ///
    /// - Returns: An array of SQL CREATE TABLE statements
    ///
    /// - Example:
    ///   ```swift
    ///   let createStatements = DataExporter.generateCreateTableStatements()
    ///   // Execute these statements to set up your database schema
    ///   ```
    public static func generateCreateTableStatements() -> [String] {
        var statements: [String] = []
        
        // Add the relationships table
        statements.append("""
        CREATE TABLE IF NOT EXISTS relationships (
            id TEXT PRIMARY KEY,
            source_id TEXT NOT NULL,
            source_type TEXT NOT NULL,
            target_id TEXT NOT NULL,
            target_type TEXT NOT NULL,
            display_name TEXT,
            created_at TIMESTAMP NOT NULL,
            confidence REAL NOT NULL,
            context TEXT,
            source TEXT NOT NULL,
            FOREIGN KEY (source_id, source_type) REFERENCES entities(id, type)
        );
        CREATE INDEX idx_relationships_source ON relationships(source_id, source_type);
        CREATE INDEX idx_relationships_target ON relationships(target_id, target_type);
        """)
        
        return statements
    }
    
    // MARK: - Vector Storage Export
    
    /// Generates a vector storage record for an entity.
    /// This creates a record suitable for embedding and storing in a vector database,
    /// containing the entity's text representation and metadata.
    ///
    /// - Parameter entity: The entity to generate a vector record for
    /// - Returns: A VectorRecord containing the entity's text and metadata
    ///
    /// - Example:
    ///   ```swift
    ///   let record = DataExporter.generateVectorRecord(person)
    ///   // Send this record to an embedding service
    ///   ```
    public static func generateVectorRecord<T: AssociatedData>(_ entity: T) -> VectorRecord {
        return VectorRecord(
            id: entity.id,
            entityType: String(describing: type(of: entity)),
            text: entity.toEmbeddingText(),
            metadata: [
                "id": entity.id,
                "type": String(describing: type(of: entity)),
                "name": entity.name
            ]
        )
    }
    
    /// Generates vector storage records for an entity's relationships.
    /// This creates records for each relationship, suitable for embedding
    /// and storing in a vector database.
    ///
    /// - Parameter entity: The entity whose relationships should be exported
    /// - Returns: An array of VectorRecord objects for relationships
    ///
    /// - Example:
    ///   ```swift
    ///   let records = DataExporter.generateRelationshipVectorRecords(person)
    ///   // Send these records to an embedding service
    ///   ```
    public static func generateRelationshipVectorRecords<T: AssociatedData>(_ entity: T) -> [VectorRecord] {
        return entity.relationships.map { relationship -> VectorRecord in
            // Create embedding text manually since toEmbeddingText doesn't exist
            let text = "Relationship from \(entity.name) (\(String(describing: type(of: entity)))) to \(relationship.id) of type \(relationship.type.rawValue)"
            
            return VectorRecord(
                id: "\(entity.id)_rel_\(relationship.id)",
                entityType: "relationship",
                text: text,
                metadata: [
                    "source_id": entity.id,
                    "source_type": String(describing: type(of: entity)),
                    "target_id": relationship.id,
                    "target_type": relationship.type.rawValue,
                    "display_name": relationship.displayName ?? "",
                    "created_at": ISO8601DateFormatter().string(from: relationship.createdAt),
                    "context": relationship.context ?? ""
                ]
            )
        }
    }
}

// MARK: - Helper Models

/// Represents a record for vector storage.
/// This structure contains the text to be embedded and metadata
/// about the entity or relationship it represents.
public struct VectorRecord: BaseEntity, Codable {
    /// Unique identifier for this vector record
    public let id: String
    
    /// Type of entity this vector represents
    public let entityType: String
    
    /// The text to be embedded
    public let text: String
    
    /// Additional metadata about the entity
    public let metadata: [String: String]
    
    /// The name of the vector record, used for display and embedding generation
    public var name: String {
        return metadata["name"] ?? "Vector \(id)"
    }
    
    /// Vector embedding (to be filled by the embedding service)
    public var embedding: [Float]?
    
    /// Creates a new vector record
    /// - Parameters:
    ///   - id: Unique identifier for this record
    ///   - entityType: Type of entity this vector represents
    ///   - text: Text to be embedded
    ///   - metadata: Additional metadata to store with the vector
    ///   - embedding: Optional pre-computed embedding
    public init(id: String, entityType: String, text: String, metadata: [String: String], embedding: [Float]? = nil) {
        self.id = id
        self.entityType = entityType
        self.text = text
        self.metadata = metadata
        self.embedding = embedding
    }
}

// MARK: - Extensions

extension Encodable {
    /// Converts an Encodable object to a dictionary.
    /// This is used internally to convert entities to dictionaries
    /// for SQL generation and other export operations.
    ///
    /// - Returns: A dictionary representation of the object
    /// - Throws: An error if conversion fails
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "DataExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert object to dictionary"])
        }
        return dictionary
    }
} 