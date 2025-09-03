#!/usr/bin/env python3
"""
Local Demo of Pi5 RAG System
This script demonstrates the system structure and workflow without requiring an API key.
"""

import os
import sys
from pathlib import Path

def show_system_structure():
    """Display the system structure and components."""
    print("🔍 Pi5 RAG System - Local Development Setup")
    print("=" * 50)
    
    print("\n📁 System Structure:")
    print("├── src/")
    print("│   ├── ingest_chroma.py     # ChromaDB ingestion")
    print("│   ├── query_chroma.py      # ChromaDB querying")
    print("│   ├── ingest.py            # Qdrant ingestion (archived)")
    print("│   └── query.py             # Qdrant querying (archived)")
    print("├── samples/")
    print("│   ├── sample1.txt          # Test document 1")
    print("│   └── sample2.md           # Test document 2")
    print("├── .venv/                   # Python virtual environment")
    print("├── chroma_storage/          # ChromaDB storage (created on first run)")
    print("├── .env                     # Environment configuration")
    print("└── requirements.txt         # Python dependencies")
    
    print("\n🔧 Configuration (.env):")
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    key = line.split('=')[0]
                    if 'API_KEY' in key:
                        print(f"  {key}=*** (hidden)")
                    else:
                        print(f"  {line.strip()}")
    else:
        print("  .env file not found")
    
    print("\n📦 Dependencies:")
    if os.path.exists('requirements.txt'):
        with open('requirements.txt', 'r') as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    print(f"  ✓ {line.strip()}")
    
    print("\n🎯 Sample Documents:")
    samples_dir = Path('samples')
    if samples_dir.exists():
        for file in samples_dir.iterdir():
            if file.is_file():
                print(f"  📄 {file.name}")
                with open(file, 'r') as f:
                    content = f.read()[:100]
                    print(f"     Preview: {content}...")

def show_workflow():
    """Show the typical workflow."""
    print("\n🚀 Typical Workflow:")
    print("1. Set OpenAI API key in .env file")
    print("2. Ingest documents: python src/ingest_chroma.py")
    print("3. Query the system: python src/query_chroma.py \"your question\"")
    print("4. View results and similarity scores")
    
    print("\n💡 Example Commands:")
    print("  # Ingest sample documents")
    print("  python src/ingest_chroma.py")
    print("")
    print("  # Query the system")
    print("  python src/query_chroma.py \"What is the escalation process?\"")
    print("  python src/query_chroma.py \"VPN down procedure\"")

def show_development_commands():
    """Show development and deployment commands."""
    print("\n🛠️ Development Commands:")
    print("  # Setup development environment")
    print("  ./dev-setup.sh setup")
    print("")
    print("  # Configure for production")
    print("  ./setup-config.sh")
    print("")
    print("  # Deploy to Pi5")
    print("  ./dev-setup.sh deploy")
    print("")
    print("  # Check system status")
    print("  ./dev-setup.sh status")

def main():
    """Main demo function."""
    show_system_structure()
    show_workflow()
    show_development_commands()
    
    print("\n" + "=" * 50)
    print("✅ Local development environment is ready!")
    print("📝 Next steps:")
    print("   1. Add your OpenAI API key to .env")
    print("   2. Run ingestion: python src/ingest_chroma.py")
    print("   3. Test queries: python src/query_chroma.py \"your question\"")
    print("   4. Configure production: ./setup-config.sh")

if __name__ == "__main__":
    main()
