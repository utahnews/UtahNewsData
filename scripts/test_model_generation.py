#!/usr/bin/env python3
"""
Model Generation Test Suite

Tests for the Pydantic to Swift model generation pipeline.
Validates parsing, type mapping, and generated code quality.

Usage:
    python test_model_generation.py
"""

import unittest
import tempfile
import shutil
import json
import os
from pathlib import Path
from pydantic_schema_parser import PydanticSchemaParser, PydanticTypeMapper
from swift_model_generator import SwiftModelGenerator


class TestPydanticTypeMapper(unittest.TestCase):
    """Test the Python to Swift type mapping functionality"""
    
    def setUp(self):
        self.mapper = PydanticTypeMapper()
    
    def test_basic_type_mapping(self):
        """Test basic type mappings"""
        test_cases = [
            ('str', 'String'),
            ('int', 'Int'),
            ('float', 'Double'),
            ('bool', 'Bool'),
            ('datetime.datetime', 'Date'),
            ('datetime.date', 'Date'),
        ]
        
        for python_type, expected_swift in test_cases:
            with self.subTest(python_type=python_type):
                swift_type, imports = self.mapper.map_type(python_type)
                self.assertEqual(swift_type, expected_swift)
    
    def test_optional_type_mapping(self):
        """Test Optional type handling"""
        test_cases = [
            ('Optional[str]', 'String?'),
            ('Optional[int]', 'Int?'),
            ('Union[str, None]', 'String?'),
        ]
        
        for python_type, expected_swift in test_cases:
            with self.subTest(python_type=python_type):
                swift_type, imports = self.mapper.map_type(python_type)
                self.assertEqual(swift_type, expected_swift)
    
    def test_list_type_mapping(self):
        """Test List type handling"""
        test_cases = [
            ('List[str]', '[String]'),
            ('List[int]', '[Int]'),
            ('List[Optional[str]]', '[String?]'),
        ]
        
        for python_type, expected_swift in test_cases:
            with self.subTest(python_type=python_type):
                swift_type, imports = self.mapper.map_type(python_type, ['str'] if 'str' in python_type else ['int'])
                self.assertEqual(swift_type, expected_swift)
    
    def test_dict_type_mapping(self):
        """Test Dict type handling"""
        test_cases = [
            ('Dict[str, int]', '[String: Int]'),
            ('Dict[str, str]', '[String: String]'),
        ]
        
        for python_type, expected_swift in test_cases:
            with self.subTest(python_type=python_type):
                generic_args = ['str', 'int'] if 'int' in python_type else ['str', 'str']
                swift_type, imports = self.mapper.map_type(python_type, generic_args)
                self.assertEqual(swift_type, expected_swift)
    
    def test_import_requirements(self):
        """Test that proper imports are included"""
        swift_type, imports = self.mapper.map_type('datetime.datetime')
        self.assertEqual(swift_type, 'Date')
        self.assertIn('Foundation', imports)


class TestPydanticSchemaParser(unittest.TestCase):
    """Test the Pydantic schema parsing functionality"""
    
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.parser = PydanticSchemaParser(self.test_dir)
    
    def tearDown(self):
        shutil.rmtree(self.test_dir)
    
    def create_test_model_file(self, filename: str, content: str):
        """Helper to create test model files"""
        file_path = Path(self.test_dir) / filename
        with open(file_path, 'w') as f:
            f.write(content)
        return file_path
    
    def test_simple_model_parsing(self):
        """Test parsing of a simple Pydantic model"""
        model_content = '''
from pydantic import BaseModel
from typing import Optional

class TestModel(BaseModel):
    name: str
    age: Optional[int] = None
    active: bool = True
'''
        
        self.create_test_model_file('test_model.py', model_content)
        models = self.parser.parse_directory()
        
        self.assertEqual(len(models), 1)
        model = models[0]
        
        self.assertEqual(model.name, 'TestModel')
        self.assertEqual(len(model.fields), 3)
        
        # Check field parsing
        name_field = next(f for f in model.fields if f.name == 'name')
        self.assertEqual(name_field.swift_type, 'String')
        self.assertFalse(name_field.is_optional)
        
        age_field = next(f for f in model.fields if f.name == 'age')
        self.assertEqual(age_field.swift_type, 'Int?')
        self.assertTrue(age_field.is_optional)
        
        active_field = next(f for f in model.fields if f.name == 'active')
        self.assertEqual(active_field.swift_type, 'Bool')
        self.assertEqual(active_field.default_value, 'True')
    
    def test_enum_parsing(self):
        """Test parsing of enums"""
        enum_content = '''
from enum import Enum

class StatusEnum(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    PENDING = "pending"
'''
        
        self.create_test_model_file('test_enum.py', enum_content)
        models = self.parser.parse_directory()
        
        self.assertEqual(len(models), 1)
        model = models[0]
        
        self.assertEqual(model.name, 'StatusEnum')
        self.assertTrue(model.is_enum)
        self.assertEqual(set(model.enum_values), {'ACTIVE', 'INACTIVE', 'PENDING'})
    
    def test_complex_field_types(self):
        """Test parsing of complex field types"""
        model_content = '''
from pydantic import BaseModel, Field
from typing import List, Dict, Optional
from datetime import datetime

class ComplexModel(BaseModel):
    tags: List[str] = Field(description="List of tags")
    metadata: Dict[str, str] = Field(default_factory=dict)
    created_at: datetime
    settings: Optional[Dict[str, int]] = None
'''
        
        self.create_test_model_file('complex_model.py', model_content)
        models = self.parser.parse_directory()
        
        self.assertEqual(len(models), 1)
        model = models[0]
        
        tags_field = next(f for f in model.fields if f.name == 'tags')
        self.assertEqual(tags_field.swift_type, '[String]')
        self.assertTrue(tags_field.is_list)
        self.assertEqual(tags_field.description, "List of tags")
        
        metadata_field = next(f for f in model.fields if f.name == 'metadata')
        self.assertEqual(metadata_field.swift_type, '[String: String]')
        self.assertTrue(metadata_field.is_dict)
        
        created_field = next(f for f in model.fields if f.name == 'created_at')
        self.assertEqual(created_field.swift_type, 'Date')


class TestSwiftModelGenerator(unittest.TestCase):
    """Test the Swift model generation functionality"""
    
    def setUp(self):
        self.output_dir = tempfile.mkdtemp()
        self.generator = SwiftModelGenerator(self.output_dir)
    
    def tearDown(self):
        shutil.rmtree(self.output_dir)
    
    def test_simple_model_generation(self):
        """Test generation of a simple Swift model"""
        model_data = {
            'name': 'TestModel',
            'base_classes': ['BaseModel'],
            'is_enum': False,
            'enum_values': None,
            'docstring': 'A test model',
            'imports': [],
            'fields': [
                {
                    'name': 'id',
                    'python_type': 'str',
                    'swift_type': 'String',
                    'is_optional': False,
                    'default_value': None,
                    'description': 'Unique identifier',
                    'is_list': False,
                    'is_dict': False,
                    'generic_args': []
                },
                {
                    'name': 'name',
                    'python_type': 'str',
                    'swift_type': 'String',
                    'is_optional': False,
                    'default_value': None,
                    'description': 'Name field',
                    'is_list': False,
                    'is_dict': False,
                    'generic_args': []
                }
            ]
        }
        
        self.generator._generate_model_file(model_data)
        
        # Verify file was created
        expected_file = Path(self.output_dir) / 'TestModel.swift'
        self.assertTrue(expected_file.exists())
        
        # Verify content
        with open(expected_file, 'r') as f:
            content = f.read()
        
        self.assertIn('public struct TestModel', content)
        self.assertIn('Codable', content)
        self.assertIn('Identifiable', content)
        self.assertIn('JSONSchemaProvider', content)
        self.assertIn('public var id: String', content)
        self.assertIn('public var name: String', content)
        self.assertIn('public init(', content)
        self.assertIn('public static var jsonSchema: String', content)
    
    def test_enum_generation(self):
        """Test generation of Swift enums"""
        enum_data = {
            'name': 'StatusEnum',
            'base_classes': ['str', 'Enum'],
            'is_enum': True,
            'enum_values': ['ACTIVE', 'INACTIVE', 'PENDING'],
            'docstring': 'Status enumeration',
            'imports': [],
            'fields': []
        }
        
        self.generator._generate_model_file(enum_data)
        
        # Verify file was created
        expected_file = Path(self.output_dir) / 'StatusEnum.swift'
        self.assertTrue(expected_file.exists())
        
        # Verify content
        with open(expected_file, 'r') as f:
            content = f.read()
        
        self.assertIn('public enum StatusEnum', content)
        self.assertIn('case active', content)
        self.assertIn('case inactive', content)
        self.assertIn('case pending', content)
        self.assertIn('String, CaseIterable', content)
    
    def test_optional_field_handling(self):
        """Test handling of optional fields"""
        model_data = {
            'name': 'OptionalModel',
            'base_classes': ['BaseModel'],
            'is_enum': False,
            'enum_values': None,
            'docstring': None,
            'imports': [],
            'fields': [
                {
                    'name': 'required_field',
                    'python_type': 'str',
                    'swift_type': 'String',
                    'is_optional': False,
                    'default_value': None,
                    'description': 'Required field',
                    'is_list': False,
                    'is_dict': False,
                    'generic_args': []
                },
                {
                    'name': 'optional_field',
                    'python_type': 'Optional[str]',
                    'swift_type': 'String?',
                    'is_optional': True,
                    'default_value': None,
                    'description': 'Optional field',
                    'is_list': False,
                    'is_dict': False,
                    'generic_args': []
                }
            ]
        }
        
        self.generator._generate_model_file(model_data)
        
        expected_file = Path(self.output_dir) / 'OptionalModel.swift'
        with open(expected_file, 'r') as f:
            content = f.read()
        
        self.assertIn('public var required_field: String', content)
        self.assertIn('public var optional_field: String?', content)
        self.assertIn('optional_field: String? = nil', content)
    
    def test_json_schema_generation(self):
        """Test JSON schema generation"""
        model_data = {
            'name': 'SchemaModel',
            'base_classes': ['BaseModel'],
            'is_enum': False,
            'enum_values': None,
            'docstring': None,
            'imports': [],
            'fields': [
                {
                    'name': 'string_field',
                    'python_type': 'str',
                    'swift_type': 'String',
                    'is_optional': False,
                    'default_value': None,
                    'description': 'String field',
                    'is_list': False,
                    'is_dict': False,
                    'generic_args': []
                },
                {
                    'name': 'int_array',
                    'python_type': 'List[int]',
                    'swift_type': '[Int]',
                    'is_optional': False,
                    'default_value': None,
                    'description': 'Integer array',
                    'is_list': True,
                    'is_dict': False,
                    'generic_args': ['int']
                }
            ]
        }
        
        self.generator._generate_model_file(model_data)
        
        expected_file = Path(self.output_dir) / 'SchemaModel.swift'
        with open(expected_file, 'r') as f:
            content = f.read()
        
        self.assertIn('public static var jsonSchema: String', content)
        self.assertIn('"type": "object"', content)
        self.assertIn('"string_field"', content)
        self.assertIn('"int_array"', content)
        self.assertIn('"type": "array"', content)


class TestIntegration(unittest.TestCase):
    """Integration tests for the complete pipeline"""
    
    def setUp(self):
        self.source_dir = tempfile.mkdtemp()
        self.output_dir = tempfile.mkdtemp()
        self.schema_file = tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False)
        self.schema_file.close()
    
    def tearDown(self):
        shutil.rmtree(self.source_dir)
        shutil.rmtree(self.output_dir)
        os.unlink(self.schema_file.name)
    
    def test_end_to_end_pipeline(self):
        """Test the complete parsing and generation pipeline"""
        # Create test Pydantic model
        model_content = '''
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum

class Priority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"

class TaskModel(BaseModel):
    """A task model for testing"""
    id: str = Field(description="Unique task identifier")
    title: str = Field(description="Task title")
    description: Optional[str] = Field(None, description="Task description")
    priority: Priority = Priority.MEDIUM
    tags: List[str] = Field(default_factory=list, description="Task tags")
    created_at: datetime = Field(description="Creation timestamp")
    completed: bool = False
'''
        
        # Write test model file
        model_file = Path(self.source_dir) / 'task_model.py'
        with open(model_file, 'w') as f:
            f.write(model_content)
        
        # Parse schemas
        parser = PydanticSchemaParser(self.source_dir)
        models = parser.parse_directory()
        
        # Verify parsing results
        self.assertEqual(len(models), 2)  # TaskModel + Priority enum
        
        # Save schema to file
        schema_data = {
            'models': [
                {
                    'name': model.name,
                    'base_classes': model.base_classes,
                    'is_enum': model.is_enum,
                    'enum_values': model.enum_values,
                    'docstring': model.docstring,
                    'imports': model.imports,
                    'fields': [
                        {
                            'name': field.name,
                            'python_type': field.python_type,
                            'swift_type': field.swift_type,
                            'is_optional': field.is_optional,
                            'default_value': field.default_value,
                            'description': field.description,
                            'is_list': field.is_list,
                            'is_dict': field.is_dict,
                            'generic_args': field.generic_args
                        }
                        for field in model.fields
                    ]
                }
                for model in models
            ]
        }
        
        with open(self.schema_file.name, 'w') as f:
            json.dump(schema_data, f)
        
        # Generate Swift models
        generator = SwiftModelGenerator(self.output_dir)
        generator.generate_from_schema(self.schema_file.name)
        
        # Verify generated files
        task_model_file = Path(self.output_dir) / 'TaskModel.swift'
        priority_enum_file = Path(self.output_dir) / 'Priority.swift'
        index_file = Path(self.output_dir) / 'GeneratedModels.swift'
        
        self.assertTrue(task_model_file.exists())
        self.assertTrue(priority_enum_file.exists())
        self.assertTrue(index_file.exists())
        
        # Verify TaskModel content
        with open(task_model_file, 'r') as f:
            task_content = f.read()
        
        self.assertIn('public struct TaskModel', content)
        self.assertIn('Codable, Identifiable', task_content)
        self.assertIn('public var id: String', task_content)
        self.assertIn('public var title: String', task_content)
        self.assertIn('public var description: String?', task_content)
        self.assertIn('public var tags: [String]', task_content)
        self.assertIn('public var created_at: Date', task_content)
        self.assertIn('public init(', task_content)
        self.assertIn('jsonSchema:', task_content)
        
        # Verify Priority enum content
        with open(priority_enum_file, 'r') as f:
            priority_content = f.read()
        
        self.assertIn('public enum Priority', priority_content)
        self.assertIn('case low', priority_content)
        self.assertIn('case medium', priority_content)
        self.assertIn('case high', priority_content)


def run_tests():
    """Run all tests"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add test classes
    test_classes = [
        TestPydanticTypeMapper,
        TestPydanticSchemaParser,
        TestSwiftModelGenerator,
        TestIntegration
    ]
    
    for test_class in test_classes:
        tests = loader.loadTestsFromTestCase(test_class)
        suite.addTests(tests)
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_tests()
    exit(0 if success else 1)