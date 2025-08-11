#!/usr/bin/env python3
"""
Installation Validation Script

This script validates that the Swift model generation system is properly
installed and configured. It performs comprehensive checks of all components.

Usage:
    python3 validate_installation.py
"""

import os
import sys
import subprocess
import tempfile
import shutil
from pathlib import Path


class ValidationError(Exception):
    """Custom exception for validation failures"""
    pass


class InstallationValidator:
    """Validates the model generation system installation"""
    
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.project_root = self.script_dir.parent
        self.passed_checks = 0
        self.total_checks = 0
        self.warnings = []
    
    def validate_all(self):
        """Run all validation checks"""
        print("🔍 Validating Swift Model Generation System Installation")
        print("=" * 60)
        
        try:
            self.check_system_requirements()
            self.check_python_environment()
            self.check_script_files()
            self.check_swift_environment()
            self.check_source_directories()
            self.test_core_functionality()
            
            self.print_summary()
            
        except ValidationError as e:
            print(f"\n❌ Validation failed: {e}")
            return False
        except Exception as e:
            print(f"\n💥 Unexpected error during validation: {e}")
            return False
        
        return True
    
    def check(self, description: str, condition: bool, required: bool = True):
        """Perform a validation check"""
        self.total_checks += 1
        
        if condition:
            print(f"✅ {description}")
            self.passed_checks += 1
        else:
            if required:
                print(f"❌ {description}")
                raise ValidationError(f"Required check failed: {description}")
            else:
                print(f"⚠️  {description}")
                self.warnings.append(description)
    
    def check_system_requirements(self):
        """Check basic system requirements"""
        print("\n📋 System Requirements")
        print("-" * 30)
        
        # Check Python
        try:
            python_version = subprocess.check_output([sys.executable, '--version'], text=True).strip()
            version_parts = python_version.split()[1].split('.')
            major, minor = int(version_parts[0]), int(version_parts[1])
            python_ok = major >= 3 and minor >= 8
            self.check(f"Python 3.8+ ({python_version})", python_ok)
        except:
            self.check("Python 3.8+", False)
        
        # Check Swift
        try:
            swift_version = subprocess.check_output(['swift', '--version'], text=True, stderr=subprocess.STDOUT)
            swift_ok = 'Swift version' in swift_version
            version_line = swift_version.split('\n')[0]
            self.check(f"Swift compiler ({version_line})", swift_ok)
        except:
            self.check("Swift compiler", False)
        
        # Check Git
        try:
            git_version = subprocess.check_output(['git', '--version'], text=True).strip()
            self.check(f"Git ({git_version})", True, required=False)
        except:
            self.check("Git (optional)", False, required=False)
    
    def check_python_environment(self):
        """Check Python environment and dependencies"""
        print("\n🐍 Python Environment")
        print("-" * 30)
        
        # Check if we can import required modules
        required_modules = [
            'ast', 'os', 'sys', 'json', 'argparse', 'pathlib', 
            'tempfile', 'unittest', 'datetime'
        ]
        
        for module in required_modules:
            try:
                __import__(module)
                self.check(f"Python module: {module}", True)
            except ImportError:
                self.check(f"Python module: {module}", False)
        
        # Check Pydantic (if available)
        try:
            import pydantic
            version = pydantic.VERSION if hasattr(pydantic, 'VERSION') else 'unknown'
            self.check(f"Pydantic ({version})", True, required=False)
        except ImportError:
            self.check("Pydantic (optional for testing)", False, required=False)
    
    def check_script_files(self):
        """Check that all required script files exist"""
        print("\n📁 Script Files")
        print("-" * 30)
        
        required_files = [
            'pydantic_schema_parser.py',
            'swift_model_generator.py', 
            'sync_models.sh',
            'setup_generation_environment.sh',
            'test_model_generation.py',
            'requirements.txt'
        ]
        
        for filename in required_files:
            file_path = self.script_dir / filename
            exists = file_path.exists()
            self.check(f"Script file: {filename}", exists)
            
            # Check if shell scripts are executable
            if filename.endswith('.sh') and exists:
                is_executable = os.access(file_path, os.X_OK)
                self.check(f"Executable: {filename}", is_executable)
        
        # Check optional files
        optional_files = [
            'demo_generation.py',
            'pre_commit_hook.py',
            'generation_config.yaml',
            'scripts_README.md'
        ]
        
        for filename in optional_files:
            file_path = self.script_dir / filename
            exists = file_path.exists()
            self.check(f"Optional file: {filename}", exists, required=False)
    
    def check_swift_environment(self):
        """Check Swift package environment"""
        print("\n🚀 Swift Environment")
        print("-" * 30)
        
        # Check Package.swift exists
        package_swift = self.project_root / 'Package.swift'
        self.check("Package.swift exists", package_swift.exists())
        
        # Check Sources directory structure
        sources_dir = self.project_root / 'Sources'
        self.check("Sources directory", sources_dir.exists())
        
        if sources_dir.exists():
            # Check for existing model directories
            utah_news_data = sources_dir / 'UtahNewsData'
            utah_news_data_models = sources_dir / 'UtahNewsDataModels'
            
            self.check("UtahNewsData module", utah_news_data.exists(), required=False)
            self.check("UtahNewsDataModels module", utah_news_data_models.exists(), required=False)
            
            # Check for required protocol files
            if utah_news_data_models.exists():
                json_schema_provider = utah_news_data_models / 'JSONSchemaProvider.swift'
                associated_data = utah_news_data_models / 'AssociatedData.swift'
                
                self.check("JSONSchemaProvider.swift", json_schema_provider.exists())
                self.check("AssociatedData.swift", associated_data.exists(), required=False)
    
    def check_source_directories(self):
        """Check source directories for Python models"""
        print("\n📂 Source Directories")
        print("-" * 30)
        
        # Check server models directory
        server_models_dir = self.project_root / '../UtahNewsAgents_Server/app/models'
        server_exists = server_models_dir.exists()
        self.check("Server models directory", server_exists, required=False)
        
        if server_exists:
            # Count Python model files
            python_files = list(server_models_dir.glob('*.py'))
            model_files = [f for f in python_files if not f.name.startswith('__')]
            file_count = len(model_files)
            
            self.check(f"Python model files ({file_count} found)", file_count > 0, required=False)
            
            if file_count > 0:
                print(f"   Found model files: {', '.join(f.name for f in model_files[:5])}" +
                      (f" and {file_count - 5} more" if file_count > 5 else ""))
    
    def test_core_functionality(self):
        """Test core functionality with minimal examples"""
        print("\n🧪 Core Functionality Tests")
        print("-" * 30)
        
        # Test type mapper
        try:
            sys.path.insert(0, str(self.script_dir))
            from pydantic_schema_parser import PydanticTypeMapper
            
            mapper = PydanticTypeMapper()
            
            # Test basic type mapping
            swift_type, imports = mapper.map_type('str')
            self.check("Type mapping: str -> String", swift_type == 'String')
            
            # Test optional mapping
            swift_type, imports = mapper.map_type('Optional[int]')
            self.check("Optional mapping: Optional[int] -> Int?", swift_type == 'Int?')
            
            # Test list mapping
            swift_type, imports = mapper.map_type('List[str]', ['str'])
            self.check("List mapping: List[str] -> [String]", swift_type == '[String]')
            
        except Exception as e:
            self.check(f"Type mapper functionality", False)
            print(f"   Error: {e}")
        
        # Test Swift generator basics
        try:
            from swift_model_generator import SwiftModelGenerator
            
            temp_dir = tempfile.mkdtemp()
            generator = SwiftModelGenerator(temp_dir)
            
            # Test that generator can be instantiated
            self.check("Swift generator instantiation", True)
            
            shutil.rmtree(temp_dir)
            
        except Exception as e:
            self.check("Swift generator functionality", False)
            print(f"   Error: {e}")
    
    def print_summary(self):
        """Print validation summary"""
        print("\n📊 Validation Summary")
        print("=" * 60)
        
        success_rate = (self.passed_checks / self.total_checks * 100) if self.total_checks > 0 else 0
        
        print(f"✅ Passed: {self.passed_checks}/{self.total_checks} checks ({success_rate:.1f}%)")
        
        if self.warnings:
            print(f"⚠️  Warnings: {len(self.warnings)}")
            for warning in self.warnings:
                print(f"   - {warning}")
        
        if success_rate >= 90:
            print("\n🎉 Installation validation PASSED!")
            print("   The system is ready for use.")
            print("\n🚀 Next steps:")
            print("   1. Run: ./setup_generation_environment.sh")
            print("   2. Run: ./sync_models.sh")
            print("   3. Build your Swift package")
        elif success_rate >= 70:
            print("\n⚠️  Installation validation PASSED with warnings")
            print("   The system should work but may have reduced functionality.")
            print("   Consider addressing the warnings above.")
        else:
            print("\n❌ Installation validation FAILED")
            print("   Please address the failed checks before using the system.")
            return False
        
        return True


def main():
    """Main validation function"""
    validator = InstallationValidator()
    success = validator.validate_all()
    
    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())