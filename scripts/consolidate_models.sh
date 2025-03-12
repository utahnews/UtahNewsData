#!/bin/bash

# Get the absolute path to the workspace root
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Folder containing the model .swift files
MODEL_DIR="$WORKSPACE_ROOT/Sources/UtahNewsData"

# Output file that will contain the consolidated (but commented-out) definitions
OUTPUT_FILE="$MODEL_DIR/ConsolidatedModels.swift"

# List of targeted model file names (without the .swift extension)
FILES=(
  "Article"
  "AssociatedData"
  "Audio"
  "CalEvent"
  "Category"
  "ExpertAnalysis"
  "Extensions"
  "Fact"
  "Jurisdiction"
  "LegalDocument"
  "Location"
  "Medialtem"
  "NewsAlert"
  "NewsContent"
  "NewsEvent"
  "NewsStory"
  "Organization"
  "Person"
  "Poll"
  "Quote"
  "ScrapeStory"
  "SocialMediaPost"
  "Source"
  "StatisticalData"
  "UserSubmission"
  "UtahNewsData"
  "Video"
)

# Create the output directory if it doesn't exist
mkdir -p "$MODEL_DIR"

# Write a header into the output file.
{
  echo "// This file consolidates model definitions (commented out) from targeted files."
  echo "// Generated on $(date)"
  echo "// Current time: $(date '+%B %d, %Y at %I:%M:%S %p %Z')"
  echo "// Do NOT uncomment this file into your code base."
  echo ""
} > "$OUTPUT_FILE"

# Process each file in the FILES array.
for BASE in "${FILES[@]}"; do
  FILE="$MODEL_DIR/$BASE.swift"
  if [[ -f "$FILE" ]]; then
    {
      echo "// File: $BASE.swift"
      # Prepend each line with '// ' so the content remains commented-out
      sed 's/^/\/\/ /' "$FILE"
      echo ""
    } >> "$OUTPUT_FILE"
  else
    echo "// Warning: File $BASE.swift not found in $MODEL_DIR" >> "$OUTPUT_FILE"
  fi
done

echo "Consolidated file created at: $OUTPUT_FILE"
