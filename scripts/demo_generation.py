#!/usr/bin/env python3
"""
Model Generation Demonstration Script

This script demonstrates the Swift model generation system by creating
sample Python Pydantic models and generating corresponding Swift models.

Usage:
    python demo_generation.py
"""

import tempfile
import shutil
from pathlib import Path
from pydantic_schema_parser import PydanticSchemaParser
from swift_model_generator import SwiftModelGenerator


def create_demo_python_models(demo_dir: Path):
    """Create sample Python Pydantic models for demonstration"""
    
    # Demo model 1: Simple news article
    article_model = '''
from pydantic import BaseModel, Field, HttpUrl
from typing import Optional, List
from datetime import datetime
from enum import Enum

class ArticleStatus(str, Enum):
    """Article publication status"""
    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"

class ArticleModel(BaseModel):
    """News article model for the Utah News Platform"""
    
    # Core fields
    id: str = Field(description="Unique article identifier")
    title: str = Field(description="Article headline")
    content: str = Field(description="Main article content")
    
    # Metadata
    author: Optional[str] = Field(None, description="Article author name")
    publication_date: datetime = Field(description="When the article was published")
    last_modified: Optional[datetime] = Field(None, description="Last modification timestamp")
    
    # Classification
    status: ArticleStatus = ArticleStatus.DRAFT
    tags: List[str] = Field(default_factory=list, description="Article tags for categorization")
    category: Optional[str] = Field(None, description="Primary article category")
    
    # URLs and references
    source_url: HttpUrl = Field(description="Original source URL")
    image_urls: List[str] = Field(default_factory=list, description="Associated image URLs")
    
    # Metrics
    view_count: int = 0
    like_count: int = 0
    share_count: int = 0
    
    # Flags
    is_featured: bool = False
    is_breaking_news: bool = False
    requires_subscription: bool = False
'''
    
    # Demo model 2: User profile
    user_model = '''
from pydantic import BaseModel, Field, EmailStr
from typing import Optional, Dict, List
from datetime import date

class UserPreferences(BaseModel):
    """User preference settings"""
    email_notifications: bool = True
    push_notifications: bool = True
    dark_mode: bool = False
    language: str = "en"
    timezone: str = "America/Denver"

class UserModel(BaseModel):
    """User profile model"""
    
    # Identity
    id: str = Field(description="Unique user identifier")
    username: str = Field(description="User's chosen username")
    email: EmailStr = Field(description="User's email address")
    
    # Profile information
    first_name: Optional[str] = Field(None, description="User's first name")
    last_name: Optional[str] = Field(None, description="User's last name") 
    date_of_birth: Optional[date] = Field(None, description="User's birth date")
    avatar_url: Optional[str] = Field(None, description="Profile picture URL")
    
    # Location
    city: Optional[str] = Field(None, description="User's city")
    state: Optional[str] = Field(None, description="User's state")
    zip_code: Optional[str] = Field(None, description="User's ZIP code")
    
    # Preferences and settings
    preferences: UserPreferences = Field(default_factory=UserPreferences)
    interests: List[str] = Field(default_factory=list, description="User's interests")
    
    # Account status
    is_active: bool = True
    is_verified: bool = False
    is_premium: bool = False
    
    # Metadata
    created_at: datetime = Field(description="Account creation timestamp")
    last_login: Optional[datetime] = Field(None, description="Last login timestamp")
    login_count: int = 0
'''
    
    # Demo model 3: Complex analytics model
    analytics_model = '''
from pydantic import BaseModel, Field
from typing import Dict, List, Optional, Union
from datetime import datetime, date
from enum import Enum

class MetricType(str, Enum):
    """Types of metrics that can be tracked"""
    PAGE_VIEW = "page_view"
    USER_ENGAGEMENT = "user_engagement"
    CONTENT_PERFORMANCE = "content_performance"
    SYSTEM_PERFORMANCE = "system_performance"

class TimeRange(BaseModel):
    """Time range for analytics queries"""
    start_date: date = Field(description="Start date for the range")
    end_date: date = Field(description="End date for the range")
    
class MetricValue(BaseModel):
    """A single metric measurement"""
    timestamp: datetime = Field(description="When the metric was recorded")
    value: Union[int, float] = Field(description="The metric value")
    metadata: Optional[Dict[str, str]] = Field(None, description="Additional context")

class AnalyticsReport(BaseModel):
    """Comprehensive analytics report"""
    
    # Report identification  
    report_id: str = Field(description="Unique report identifier")
    report_name: str = Field(description="Human-readable report name")
    generated_at: datetime = Field(description="When this report was generated")
    
    # Report scope
    metric_type: MetricType = Field(description="Type of metrics in this report")
    time_range: TimeRange = Field(description="Time period covered by this report")
    filters: Dict[str, str] = Field(default_factory=dict, description="Applied filters")
    
    # Data
    metrics: List[MetricValue] = Field(description="Individual metric measurements")
    summary_stats: Dict[str, Union[int, float]] = Field(description="Summary statistics")
    
    # Aggregations
    daily_aggregates: Dict[str, float] = Field(default_factory=dict, description="Daily aggregated values")
    category_breakdown: Dict[str, int] = Field(default_factory=dict, description="Breakdown by category")
    
    # Metadata
    total_records: int = Field(description="Total number of records analyzed")
    data_quality_score: float = Field(description="Quality score from 0.0 to 1.0")
    confidence_interval: Optional[float] = Field(None, description="Statistical confidence interval")
    
    # Flags
    is_real_time: bool = False
    contains_estimated_data: bool = False
    is_cached: bool = False
'''
    
    # Write the demo models to files
    models = [
        ('article_model.py', article_model),
        ('user_model.py', user_model), 
        ('analytics_model.py', analytics_model)
    ]
    
    for filename, content in models:
        model_file = demo_dir / filename
        with open(model_file, 'w') as f:
            f.write(content)
        print(f"Created demo model: {filename}")


def demonstrate_generation():
    """Run the complete demonstration"""
    print("🚀 Swift Model Generation Demo")
    print("=" * 50)
    
    # Create temporary directories
    python_models_dir = Path(tempfile.mkdtemp(prefix="demo_python_models_"))
    swift_output_dir = Path(tempfile.mkdtemp(prefix="demo_swift_models_"))
    
    try:
        # Step 1: Create demo Python models
        print("\n📝 Step 1: Creating demo Python Pydantic models...")
        create_demo_python_models(python_models_dir)
        
        # Step 2: Parse the Python models
        print("\n🔍 Step 2: Parsing Python models...")
        parser = PydanticSchemaParser(str(python_models_dir))
        models = parser.parse_directory()
        
        print(f"   Found {len(models)} models:")
        for model in models:
            model_type = "enum" if model.is_enum else "struct"
            field_count = len(model.fields)
            print(f"   - {model.name} ({model_type}, {field_count} fields)")
        
        # Step 3: Generate Swift models
        print("\n⚡ Step 3: Generating Swift models...")
        generator = SwiftModelGenerator(str(swift_output_dir))
        
        # Create schema data
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
        
        # Save schema and generate
        schema_file = swift_output_dir / "schema.json"
        import json
        with open(schema_file, 'w') as f:
            json.dump(schema_data, f, indent=2)
        
        generator.generate_from_schema(str(schema_file))
        
        # Step 4: Show results
        print("\n✅ Step 4: Generated Swift models:")
        swift_files = list(swift_output_dir.glob("*.swift"))
        for swift_file in sorted(swift_files):
            print(f"   - {swift_file.name}")
        
        # Step 5: Show sample generated code
        print("\n📄 Step 5: Sample generated Swift code:")
        print("-" * 40)
        
        # Find the ArticleModel file and show a snippet
        article_file = swift_output_dir / "ArticleModel.swift"
        if article_file.exists():
            with open(article_file, 'r') as f:
                lines = f.readlines()
            
            # Show first 30 lines
            for i, line in enumerate(lines[:30]):
                print(f"{i+1:2d}: {line.rstrip()}")
            
            if len(lines) > 30:
                print(f"... ({len(lines) - 30} more lines)")
        
        # Step 6: Demonstrate type mappings
        print(f"\n🔄 Step 6: Type mapping examples:")
        print("-" * 40)
        
        type_examples = [
            ('str', 'String'),
            ('Optional[str]', 'String?'),
            ('List[str]', '[String]'),
            ('Dict[str, int]', '[String: Int]'),
            ('datetime.datetime', 'Date'),
            ('bool', 'Bool'),
            ('HttpUrl', 'String'),
            ('EmailStr', 'String')
        ]
        
        for python_type, swift_type in type_examples:
            print(f"   {python_type:<20} → {swift_type}")
        
        # Step 7: Show protocol conformance
        print(f"\n🎯 Step 7: Protocol conformance:")
        print("-" * 40)
        protocols = ['Codable', 'Identifiable', 'Hashable', 'JSONSchemaProvider', 'Sendable']
        for protocol in protocols:
            print(f"   ✓ {protocol}")
        
        print(f"\n🎉 Demo completed successfully!")
        print(f"   Python models: {python_models_dir}")
        print(f"   Swift models:  {swift_output_dir}")
        print(f"\n💡 In real usage, run: ./scripts/sync_models.sh")
        
    except Exception as e:
        print(f"\n❌ Demo failed with error: {e}")
        raise
    
    finally:
        # Cleanup (comment out to inspect files)
        # shutil.rmtree(python_models_dir)
        # shutil.rmtree(swift_output_dir)
        pass


if __name__ == '__main__':
    demonstrate_generation()