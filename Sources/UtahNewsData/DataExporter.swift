import Foundation

/// Utilities for exporting UtahNewsData models to various formats
public class DataExporter {
    
    // MARK: - Relational Database Export
    
    /// Exports an entity to a SQL insert statement
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
    
    /// Exports relationships to SQL insert statements
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
                "confidence": relationship.confidence,
                "context": relationship.context as Any,
                "source": relationship.source.rawValue
            ]
            
            // Generate column names and values
            let columns = dict.keys.joined(separator: ", ")
            let placeholders = dict.keys.map { ":\($0)" }.joined(separator: ", ")
            
            // Create SQL statement
            return "INSERT INTO relationships (\(columns)) VALUES (\(placeholders));"
        }
    }
    
    /// Generates CREATE TABLE statements for all entity types
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
    
    /// Generates a vector storage record for an entity
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
    
    /// Generates vector storage records for an entity's relationships
    public static func generateRelationshipVectorRecords<T: AssociatedData>(_ entity: T) -> [VectorRecord] {
        return entity.relationships.map { relationship -> VectorRecord in
            let text = relationship.toEmbeddingText(
                sourceEntityName: entity.name,
                sourceEntityType: String(describing: type(of: entity))
            )
            
            return VectorRecord(
                id: "\(entity.id)_rel_\(relationship.id)",
                entityType: "relationship",
                text: text,
                metadata: [
                    "source_id": entity.id,
                    "source_type": String(describing: type(of: entity)),
                    "target_id": relationship.id,
                    "target_type": relationship.type.rawValue,
                    "relationship_type": relationship.type.rawValue
                ]
            )
        }
    }
}

// MARK: - Helper Models

/// Represents a record for vector storage
public struct VectorRecord: Codable {
    /// Unique identifier for this vector record
    public let id: String
    
    /// Type of entity this vector represents
    public let entityType: String
    
    /// Text to be embedded
    public let text: String
    
    /// Additional metadata to store with the vector
    public let metadata: [String: String]
    
    /// Vector embedding (to be filled by the embedding service)
    public var embedding: [Float]?
    
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
    /// Converts an Encodable object to a dictionary
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "DataExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert object to dictionary"])
        }
        return dictionary
    }
} 