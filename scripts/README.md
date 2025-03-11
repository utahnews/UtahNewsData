# UtahNewsData Scripts

This directory contains utility scripts for maintaining the UtahNewsData package documentation and code organization.

## Available Scripts

### `consolidate_models.sh`

A shell script that consolidates all model definitions into a single reference file.

**Purpose:**
- Creates a comprehensive reference of all model definitions in one place
- Helps maintain documentation and code review
- Useful for understanding the full model hierarchy

**Usage:**
```bash
./consolidate_models.sh
```

**When to use:**
- After adding new models
- After making significant changes to existing models
- After updating model conformances (e.g., adding JSONSchemaProvider)
- Before submitting pull requests that modify models

**Output:**
- Creates/updates `Sources/UtahNewsData/ConsolidatedModels.swift`
- All model definitions are commented out to prevent accidental usage
- Includes timestamps and file origins

### `generate_readme.swift`

A Swift script that automatically generates the project's main README.md file.

**Purpose:**
- Maintains up-to-date project documentation
- Ensures consistency between code and documentation
- Automatically includes all models and their descriptions
- Generates usage examples and API documentation

**Usage:**
```bash
./generate_readme.swift
```

**When to use:**
- After adding new features or models
- After updating model conformances
- After adding new usage examples
- Before releasing new versions
- After significant codebase changes

**Output:**
- Creates/updates the main project `README.md`
- Includes:
  - Package overview
  - Installation instructions
  - Core concepts
  - Entity models list
  - Usage examples
  - RAG utilities documentation
  - JSON schema generation information
  - Model reference
  - License information

## Best Practices

1. **Run Order:**
   - Run `consolidate_models.sh` first to update the model reference
   - Then run `generate_readme.swift` to update documentation

2. **Version Control:**
   - Commit the script outputs (`ConsolidatedModels.swift` and `README.md`)
   - Review the changes before committing

3. **Maintenance:**
   - Keep scripts up to date with new features
   - Update script documentation when changing functionality
   - Test scripts after making modifications

## Script Maintenance

When modifying these scripts:

1. **consolidate_models.sh:**
   - Update the model list in `FILES` array when adding new models
   - Maintain the comment format for consistency
   - Ensure proper file paths and permissions

2. **generate_readme.swift:**
   - Update sections when adding new features
   - Maintain consistent formatting
   - Add new examples when appropriate
   - Update regex patterns if comment styles change