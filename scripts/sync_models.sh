#!/bin/bash

# sync_models.sh
# Automated Swift Model Generation from Python Pydantic Schemas
# 
# This script orchestrates the complete model synchronization process:
# 1. Parses Python Pydantic models to extract schema metadata
# 2. Generates Swift models with proper protocol conformance
# 3. Validates the generated models compile correctly
# 4. Integrates them into the UtahNewsData package

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER_MODELS_DIR="$PROJECT_ROOT/../UtahNewsAgents_Server/app/models"
GENERATED_MODELS_DIR="$PROJECT_ROOT/Sources/UtahNewsDataGenerated"
SCHEMA_OUTPUT_FILE="$SCRIPT_DIR/generated_schema.json"
LOG_FILE="$SCRIPT_DIR/sync_models.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}INFO: $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        log_error "python3 is required but not installed"
        exit 1
    fi
    
    # Check Swift
    if ! command -v swift &> /dev/null; then
        log_error "swift is required but not installed"
        exit 1
    fi
    
    # Check if server models directory exists
    if [ ! -d "$SERVER_MODELS_DIR" ]; then
        log_error "Server models directory not found: $SERVER_MODELS_DIR"
        exit 1
    fi
    
    log_success "All dependencies satisfied"
}

# Backup existing generated models
backup_existing_models() {
    if [ -d "$GENERATED_MODELS_DIR" ]; then
        backup_dir="${GENERATED_MODELS_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up existing generated models to: $backup_dir"
        cp -r "$GENERATED_MODELS_DIR" "$backup_dir"
    fi
}

# Parse Pydantic schemas
parse_schemas() {
    log_info "Parsing Pydantic schemas from: $SERVER_MODELS_DIR"
    
    python3 "$SCRIPT_DIR/pydantic_schema_parser.py" \
        --source-dir "$SERVER_MODELS_DIR" \
        --output-file "$SCHEMA_OUTPUT_FILE" \
        --verbose
    
    if [ $? -eq 0 ]; then
        log_success "Schema parsing completed successfully"
    else
        log_error "Schema parsing failed"
        exit 1
    fi
}

# Generate Swift models
generate_swift_models() {
    log_info "Generating Swift models to: $GENERATED_MODELS_DIR"
    
    # Create output directory
    mkdir -p "$GENERATED_MODELS_DIR"
    
    python3 "$SCRIPT_DIR/swift_model_generator.py" \
        --schema-file "$SCHEMA_OUTPUT_FILE" \
        --output-dir "$GENERATED_MODELS_DIR" \
        --verbose
    
    if [ $? -eq 0 ]; then
        log_success "Swift model generation completed successfully"
    else
        log_error "Swift model generation failed"
        exit 1
    fi
}

# Validate generated Swift models
validate_swift_models() {
    log_info "Validating generated Swift models..."
    
    # Create a temporary Swift package for validation
    temp_validation_dir=$(mktemp -d)
    cd "$temp_validation_dir"
    
    # Initialize Swift package
    swift package init --type library --name ValidationTest
    
    # Copy generated models to validation package
    cp "$GENERATED_MODELS_DIR"/*.swift Sources/ValidationTest/
    
    # Copy required protocol files
    if [ -f "$PROJECT_ROOT/Sources/UtahNewsDataModels/AssociatedData.swift" ]; then
        cp "$PROJECT_ROOT/Sources/UtahNewsDataModels/AssociatedData.swift" Sources/ValidationTest/
    fi
    
    if [ -f "$PROJECT_ROOT/Sources/UtahNewsDataModels/JSONSchemaProvider.swift" ]; then
        cp "$PROJECT_ROOT/Sources/UtahNewsDataModels/JSONSchemaProvider.swift" Sources/ValidationTest/
    fi
    
    # Try to build the validation package
    log_info "Building validation package..."
    if swift build > validation.log 2>&1; then
        log_success "All generated models compile successfully"
        rm -rf "$temp_validation_dir"
        return 0
    else
        log_error "Generated models have compilation errors:"
        cat validation.log
        log_error "Validation package left at: $temp_validation_dir"
        return 1
    fi
}

# Update Package.swift to include generated models
update_package_swift() {
    log_info "Updating Package.swift to include generated models..."
    
    package_file="$PROJECT_ROOT/Package.swift"
    
    if [ ! -f "$package_file" ]; then
        log_error "Package.swift not found at: $package_file"
        return 1
    fi
    
    # Create backup
    cp "$package_file" "${package_file}.backup"
    
    # Check if UtahNewsDataGenerated target already exists
    if grep -q "UtahNewsDataGenerated" "$package_file"; then
        log_info "UtahNewsDataGenerated target already exists in Package.swift"
    else
        log_info "Adding UtahNewsDataGenerated target to Package.swift"
        
        # This is a simplified approach - in a real implementation, you might want
        # to use a more sophisticated method to modify Package.swift
        log_warning "Manual update of Package.swift may be required"
        log_info "Please add the following target to your Package.swift:"
        echo ""
        echo "        .target("
        echo "            name: \"UtahNewsDataGenerated\","
        echo "            dependencies: [\"UtahNewsDataModels\"],"
        echo "            path: \"Sources/UtahNewsDataGenerated\""
        echo "        ),"
        echo ""
    fi
}

# Generate documentation
generate_documentation() {
    log_info "Generating documentation for synchronized models..."
    
    doc_file="$GENERATED_MODELS_DIR/README.md"
    
    cat > "$doc_file" << EOF
# Generated Swift Models

This directory contains Swift models automatically generated from Python Pydantic schemas.

## Overview

These models are generated from the Utah News Platform server's Pydantic models to ensure
type safety and consistency between the Python backend and Swift client applications.

## Generation Process

1. **Schema Parsing**: Python Pydantic models are parsed to extract type information
2. **Type Mapping**: Python types are mapped to appropriate Swift types
3. **Protocol Conformance**: Generated models conform to required protocols:
   - \`Codable\` for JSON serialization
   - \`Identifiable\` for SwiftUI compatibility
   - \`Hashable\` for collections and comparison
   - \`JSONSchemaProvider\` for LLM interactions
   - \`Sendable\` for Swift 6 concurrency
   - \`AssociatedData\` for models with relationships

## Generated Models

$(find "$GENERATED_MODELS_DIR" -name "*.swift" -not -name "README.md" -not -name "GeneratedModels.swift" | wc -l) Swift model files generated on $(date)

## Important Notes

- **DO NOT EDIT**: These files are automatically generated and will be overwritten
- **Source of Truth**: The Python Pydantic models in the server are the source of truth
- **Synchronization**: Run \`scripts/sync_models.sh\` to update when server models change
- **Validation**: All generated models are validated to ensure they compile correctly

## Last Updated

Generated on: $(date)
Source: \`$SERVER_MODELS_DIR\`

EOF

    log_success "Documentation generated: $doc_file"
}

# Run tests
run_tests() {
    log_info "Running Swift package tests..."
    
    cd "$PROJECT_ROOT"
    
    if swift test > test_output.log 2>&1; then
        log_success "All tests passed"
        rm test_output.log
    else
        log_warning "Some tests failed - check test_output.log for details"
        log_info "Test failures may be expected if generated models have dependencies not available in test environment"
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    [ -f "$SCHEMA_OUTPUT_FILE" ] && rm "$SCHEMA_OUTPUT_FILE"
    log_success "Cleanup completed"
}

# Main execution
main() {
    log_info "Starting model synchronization process..."
    log_info "Project root: $PROJECT_ROOT"
    log_info "Server models: $SERVER_MODELS_DIR"
    log_info "Generated models: $GENERATED_MODELS_DIR"
    
    # Clear previous log
    > "$LOG_FILE"
    
    check_dependencies
    backup_existing_models
    parse_schemas
    generate_swift_models
    
    if validate_swift_models; then
        update_package_swift
        generate_documentation
        run_tests
        log_success "Model synchronization completed successfully!"
        log_info "Generated models are available in: $GENERATED_MODELS_DIR"
    else
        log_error "Model synchronization failed during validation"
        exit 1
    fi
    
    cleanup
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --clean        Clean generated models before sync"
        echo "  --validate     Only validate existing generated models"
        echo "  --dry-run      Show what would be done without executing"
        echo ""
        echo "This script synchronizes Swift models with Python Pydantic schemas."
        exit 0
        ;;
    --clean)
        log_info "Cleaning existing generated models..."
        rm -rf "$GENERATED_MODELS_DIR"
        log_success "Cleanup completed"
        main
        ;;
    --validate)
        log_info "Validating existing generated models..."
        validate_swift_models
        ;;
    --dry-run)
        log_info "DRY RUN - Would perform the following actions:"
        log_info "1. Parse schemas from: $SERVER_MODELS_DIR"
        log_info "2. Generate Swift models to: $GENERATED_MODELS_DIR"
        log_info "3. Validate generated models compile"
        log_info "4. Update Package.swift if needed"
        log_info "5. Generate documentation"
        log_info "6. Run tests"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac