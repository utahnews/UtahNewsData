#!/usr/bin/env python3
"""
Pre-commit Hook for Model Synchronization

This script can be used as a Git pre-commit hook to automatically
synchronize Swift models when Python Pydantic models are modified.

To install as a Git hook:
    cp scripts/pre_commit_hook.py .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit

Or use with pre-commit framework:
    Add to .pre-commit-config.yaml
"""

import subprocess
import sys
import os
from pathlib import Path


def get_changed_files():
    """Get list of files changed in this commit"""
    try:
        # Get staged files
        result = subprocess.run(
            ['git', 'diff', '--cached', '--name-only'],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip().split('\n') if result.stdout.strip() else []
    except subprocess.CalledProcessError:
        return []


def has_python_model_changes(changed_files):
    """Check if any Python model files were changed"""
    model_patterns = [
        'UtahNewsAgents_Server/app/models/',
        'models.py',
        'schema.py'
    ]
    
    for file_path in changed_files:
        for pattern in model_patterns:
            if pattern in file_path and file_path.endswith('.py'):
                return True
    
    return False


def run_model_sync():
    """Run the model synchronization script"""
    script_dir = Path(__file__).parent
    sync_script = script_dir / 'sync_models.sh'
    
    if not sync_script.exists():
        print(f"Warning: Model sync script not found at {sync_script}")
        return True
    
    try:
        print("Python model changes detected. Synchronizing Swift models...")
        result = subprocess.run([str(sync_script)], check=True)
        print("✅ Model synchronization completed successfully")
        
        # Stage any newly generated files
        subprocess.run(['git', 'add', 'Sources/UtahNewsDataGenerated/'], check=False)
        
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Model synchronization failed: {e}")
        print("Commit aborted. Please fix the model synchronization issues and try again.")
        return False


def main():
    """Main pre-commit hook logic"""
    changed_files = get_changed_files()
    
    if not changed_files:
        # No files changed, nothing to do
        return 0
    
    if has_python_model_changes(changed_files):
        # Python model files were changed, run synchronization
        if run_model_sync():
            return 0
        else:
            return 1
    
    # No model changes, proceed with commit
    return 0


if __name__ == '__main__':
    sys.exit(main())