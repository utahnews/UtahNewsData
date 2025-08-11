#!/bin/bash

# setup_generation_environment.sh
# Set up the environment for Swift model generation from Pydantic schemas

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Setting up Swift model generation environment..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed"
    exit 1
fi

# Create virtual environment if it doesn't exist
VENV_DIR="$SCRIPT_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Install requirements
echo "Installing Python dependencies..."
pip install -r "$SCRIPT_DIR/requirements.txt"

# Make scripts executable
chmod +x "$SCRIPT_DIR/sync_models.sh"
chmod +x "$SCRIPT_DIR/pydantic_schema_parser.py"
chmod +x "$SCRIPT_DIR/swift_model_generator.py"

# Run tests to validate setup
echo "Running validation tests..."
if python3 "$SCRIPT_DIR/test_model_generation.py"; then
    echo "✅ Setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Run './scripts/sync_models.sh' to generate Swift models"
    echo "2. Update your Package.swift to include the generated models"
    echo "3. Build your Swift package to validate the generated models"
else
    echo "❌ Setup validation failed. Check the test output above."
    exit 1
fi