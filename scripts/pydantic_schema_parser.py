#!/usr/bin/env python3
"""
Pydantic Schema Parser for Swift Model Generation

This script parses Python Pydantic models and extracts schema information
to generate corresponding Swift models with proper type mapping and protocol conformance.

Usage:
    python pydantic_schema_parser.py --source-dir <path-to-python-models> --output-dir <path-to-swift-output>
"""

import ast
import os
import sys
import json
import argparse
import importlib.util
import inspect
from typing import Dict, List, Any, Optional, Union, get_origin, get_args
from pathlib import Path
from dataclasses import dataclass
from datetime import datetime, date
from enum import Enum

# Add the server directory to Python path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../UtahNewsAgents_Server'))

try:
    from pydantic import BaseModel
    from pydantic.fields import FieldInfo
except ImportError:
    print("Error: pydantic is required. Install with: pip install pydantic")
    sys.exit(1)


@dataclass
class FieldMetadata:
    """Metadata for a Pydantic field"""
    name: str
    python_type: str
    swift_type: str
    is_optional: bool
    default_value: Optional[str]
    description: Optional[str]
    is_list: bool
    is_dict: bool
    generic_args: List[str]


@dataclass
class ModelMetadata:
    """Metadata for a Pydantic model"""
    name: str
    base_classes: List[str]
    fields: List[FieldMetadata]
    is_enum: bool
    enum_values: Optional[List[str]]
    docstring: Optional[str]
    imports: List[str]


class PydanticTypeMapper:
    """Maps Python types to Swift types"""
    
    TYPE_MAPPING = {
        # Basic types
        'str': 'String',
        'int': 'Int',
        'float': 'Double',
        'bool': 'Bool',
        'bytes': 'Data',
        
        # Date/time types
        'datetime.datetime': 'Date',
        'datetime.date': 'Date',
        'datetime.time': 'Date',  # Swift doesn't have separate time type
        
        # Special Pydantic types
        'pydantic.types.EmailStr': 'String',
        'pydantic.HttpUrl': 'String',
        'pydantic.AnyUrl': 'String',
        'uuid.UUID': 'String',
        
        # Collections
        'list': 'Array',
        'dict': 'Dictionary',
        'set': 'Set',
        
        # Optional/Union handling is done separately
    }
    
    SWIFT_IMPORTS = {
        'Date': 'Foundation',
        'Data': 'Foundation',
        'UUID': 'Foundation',
    }
    
    @classmethod
    def map_type(cls, python_type: str, generic_args: List[str] = None) -> tuple[str, List[str]]:
        """
        Map a Python type to Swift type
        Returns: (swift_type, required_imports)
        """
        imports = []
        
        # Handle Optional types
        if python_type.startswith('Optional[') or python_type.startswith('Union['):
            # Extract the inner type from Optional[T] or Union[T, NoneType]
            inner_type = cls._extract_optional_type(python_type)
            if inner_type:
                swift_type, inner_imports = cls.map_type(inner_type, generic_args)
                return f"{swift_type}?", inner_imports
        
        # Handle List types
        if python_type.startswith('List[') or python_type == 'list':
            if generic_args and len(generic_args) > 0:
                inner_swift, inner_imports = cls.map_type(generic_args[0])
                imports.extend(inner_imports)
                return f"[{inner_swift}]", imports
            return "[Any]", imports
        
        # Handle Dict types
        if python_type.startswith('Dict[') or python_type == 'dict':
            if generic_args and len(generic_args) >= 2:
                key_swift, key_imports = cls.map_type(generic_args[0])
                value_swift, value_imports = cls.map_type(generic_args[1])
                imports.extend(key_imports)
                imports.extend(value_imports)
                return f"[{key_swift}: {value_swift}]", imports
            return "[String: Any]", imports
        
        # Handle Literal types (convert to String for now)
        if python_type.startswith('Literal['):
            return "String", imports
        
        # Check direct mapping
        swift_type = cls.TYPE_MAPPING.get(python_type, python_type)
        
        # Add required imports
        if swift_type in cls.SWIFT_IMPORTS:
            imports.append(cls.SWIFT_IMPORTS[swift_type])
        
        # Handle custom model types (assume they're defined in the same package)
        if swift_type not in cls.TYPE_MAPPING.values() and swift_type != python_type:
            # This is likely a custom model, keep as-is
            pass
        elif swift_type == python_type and '.' in python_type:
            # Extract just the class name for custom types
            swift_type = python_type.split('.')[-1]
        
        return swift_type, imports
    
    @classmethod
    def _extract_optional_type(cls, type_str: str) -> Optional[str]:
        """Extract the inner type from Optional[T] or Union[T, NoneType]"""
        if type_str.startswith('Optional['):
            return type_str[9:-1]  # Remove 'Optional[' and ']'
        elif type_str.startswith('Union['):
            # Handle Union[T, NoneType] patterns
            inner = type_str[6:-1]  # Remove 'Union[' and ']'
            parts = [p.strip() for p in inner.split(',')]
            non_none_parts = [p for p in parts if p not in ['None', 'NoneType', 'type(None)']]
            if len(non_none_parts) == 1:
                return non_none_parts[0]
        return None


class PydanticSchemaParser:
    """Parses Pydantic models from Python source files"""
    
    def __init__(self, source_dir: str):
        self.source_dir = Path(source_dir)
        self.models: List[ModelMetadata] = []
        self.type_mapper = PydanticTypeMapper()
    
    def parse_directory(self) -> List[ModelMetadata]:
        """Parse all Python files in the source directory"""
        python_files = list(self.source_dir.rglob("*.py"))
        
        for py_file in python_files:
            if py_file.name.startswith('__'):
                continue
            
            try:
                self._parse_file(py_file)
            except Exception as e:
                print(f"Warning: Failed to parse {py_file}: {e}")
                continue
        
        return self.models
    
    def _parse_file(self, file_path: Path):
        """Parse a single Python file for Pydantic models"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Parse AST
            tree = ast.parse(content)
            
            # Extract models from AST
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    model_meta = self._parse_class(node, content)
                    if model_meta:
                        self.models.append(model_meta)
                        
        except Exception as e:
            print(f"Error parsing {file_path}: {e}")
    
    def _parse_class(self, class_node: ast.ClassDef, source_content: str) -> Optional[ModelMetadata]:
        """Parse a class definition to extract model metadata"""
        
        # Check if it's a Pydantic model
        base_classes = []
        is_pydantic_model = False
        is_enum = False
        
        for base in class_node.bases:
            if isinstance(base, ast.Name):
                base_name = base.id
                base_classes.append(base_name)
                if base_name in ['BaseModel', 'StrictBaseModel']:
                    is_pydantic_model = True
            elif isinstance(base, ast.Attribute):
                # Handle cases like pydantic.BaseModel
                base_name = ast.unparse(base)
                base_classes.append(base_name)
                if 'BaseModel' in base_name:
                    is_pydantic_model = True
                elif 'Enum' in base_name:
                    is_enum = True
        
        if not is_pydantic_model and not is_enum:
            return None
        
        # Parse fields
        fields = []
        enum_values = []
        
        for node in class_node.body:
            if isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
                # Field with type annotation
                field_meta = self._parse_field(node)
                if field_meta:
                    fields.append(field_meta)
            elif isinstance(node, ast.Assign) and is_enum:
                # Enum value
                for target in node.targets:
                    if isinstance(target, ast.Name):
                        enum_values.append(target.id)
        
        # Extract docstring
        docstring = None
        if (class_node.body and 
            isinstance(class_node.body[0], ast.Expr) and
            isinstance(class_node.body[0].value, ast.Constant) and
            isinstance(class_node.body[0].value.value, str)):
            docstring = class_node.body[0].value.value
        
        return ModelMetadata(
            name=class_node.name,
            base_classes=base_classes,
            fields=fields,
            is_enum=is_enum,
            enum_values=enum_values if is_enum else None,
            docstring=docstring,
            imports=self._extract_imports(source_content)
        )
    
    def _parse_field(self, ann_assign: ast.AnnAssign) -> Optional[FieldMetadata]:
        """Parse a field annotation to extract metadata"""
        field_name = ann_assign.target.id
        
        # Get type information
        type_str = ast.unparse(ann_assign.annotation)
        
        # Parse default value and Field() parameters
        default_value = None
        description = None
        
        if ann_assign.value:
            if isinstance(ann_assign.value, ast.Call):
                # Handle Field() calls
                if isinstance(ann_assign.value.func, ast.Name) and ann_assign.value.func.id == 'Field':
                    # Extract Field parameters
                    for keyword in ann_assign.value.keywords:
                        if keyword.arg == 'description':
                            if isinstance(keyword.value, ast.Constant):
                                description = keyword.value.value
                        elif keyword.arg == 'default':
                            default_value = ast.unparse(keyword.value)
                    
                    # Check for positional default
                    if ann_assign.value.args:
                        default_value = ast.unparse(ann_assign.value.args[0])
            else:
                # Simple default value
                default_value = ast.unparse(ann_assign.value)
        
        # Analyze type
        is_optional = 'Optional[' in type_str or 'Union[' in type_str
        is_list = 'List[' in type_str or type_str == 'list'
        is_dict = 'Dict[' in type_str or type_str == 'dict'
        
        # Extract generic arguments
        generic_args = self._extract_generic_args(type_str)
        
        # Map to Swift type
        swift_type, imports = self.type_mapper.map_type(type_str, generic_args)
        
        return FieldMetadata(
            name=field_name,
            python_type=type_str,
            swift_type=swift_type,
            is_optional=is_optional,
            default_value=default_value,
            description=description,
            is_list=is_list,
            is_dict=is_dict,
            generic_args=generic_args
        )
    
    def _extract_generic_args(self, type_str: str) -> List[str]:
        """Extract generic type arguments from a type string"""
        args = []
        
        # Simple regex-like parsing for common patterns
        if '[' in type_str and ']' in type_str:
            start = type_str.find('[')
            end = type_str.rfind(']')
            if start < end:
                inner = type_str[start+1:end]
                # Split by comma, handling nested brackets
                args = self._split_type_args(inner)
        
        return args
    
    def _split_type_args(self, args_str: str) -> List[str]:
        """Split type arguments by comma, respecting nested brackets"""
        args = []
        current_arg = ""
        bracket_depth = 0
        
        for char in args_str:
            if char == '[':
                bracket_depth += 1
            elif char == ']':
                bracket_depth -= 1
            elif char == ',' and bracket_depth == 0:
                args.append(current_arg.strip())
                current_arg = ""
                continue
            
            current_arg += char
        
        if current_arg.strip():
            args.append(current_arg.strip())
        
        return args
    
    def _extract_imports(self, source_content: str) -> List[str]:
        """Extract import statements from source content"""
        imports = []
        try:
            tree = ast.parse(source_content)
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        imports.append(alias.name)
                elif isinstance(node, ast.ImportFrom):
                    module = node.module or ""
                    for alias in node.names:
                        imports.append(f"{module}.{alias.name}")
        except:
            pass
        return imports


def main():
    parser = argparse.ArgumentParser(description='Parse Pydantic models for Swift generation')
    parser.add_argument('--source-dir', required=True, help='Directory containing Python Pydantic models')
    parser.add_argument('--output-file', required=True, help='Output JSON file for parsed schema')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')
    
    args = parser.parse_args()
    
    if args.verbose:
        print(f"Parsing Pydantic models from: {args.source_dir}")
    
    # Parse models
    schema_parser = PydanticSchemaParser(args.source_dir)
    models = schema_parser.parse_directory()
    
    if args.verbose:
        print(f"Found {len(models)} models")
    
    # Convert to JSON-serializable format
    output_data = {
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
        ],
        'generated_at': datetime.now().isoformat(),
        'source_directory': str(args.source_dir)
    }
    
    # Write output
    with open(args.output_file, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)
    
    print(f"Parsed schema written to: {args.output_file}")


if __name__ == '__main__':
    main()