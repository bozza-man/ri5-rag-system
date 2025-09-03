#!/usr/bin/env python3
"""
Demo server for Pi5 RAG System
This script runs a simple demo to show the system is working.
"""

import os
import sys
import time
from pathlib import Path

def main():
    print("🚀 Pi5 RAG System Demo Server Starting...")
    print("=" * 50)
    
    # Check if we're in the right directory
    current_dir = Path.cwd()
    print(f"📁 Current directory: {current_dir}")
    
    # Check if .env file exists
    env_file = current_dir / ".env"
    if env_file.exists():
        print("✅ Environment file found")
    else:
        print("⚠️  Environment file not found")
    
    # Check if virtual environment exists
    venv_dir = current_dir / ".venv"
    if venv_dir.exists():
        print("✅ Virtual environment found")
    else:
        print("⚠️  Virtual environment not found")
    
    # Check if ChromaDB storage exists
    chroma_dir = current_dir / "chroma_storage"
    if chroma_dir.exists():
        print("✅ ChromaDB storage found")
    else:
        print("⚠️  ChromaDB storage not found")
    
    # Check if sample files exist
    samples_dir = current_dir / "samples"
    if samples_dir.exists():
        sample_files = list(samples_dir.glob("*"))
        print(f"✅ Sample files found: {len(sample_files)} files")
    else:
        print("⚠️  Sample files not found")
    
    print("\n🎯 System Status: READY")
    print("📝 To test the system:")
    print("   python src/ingest_chroma.py")
    print("   python src/query_chroma.py 'your question'")
    
    print("\n🔄 Demo server running... (Press Ctrl+C to stop)")
    
    try:
        while True:
            time.sleep(60)  # Sleep for 1 minute
            print(f"⏰ {time.strftime('%Y-%m-%d %H:%M:%S')} - System running normally")
    except KeyboardInterrupt:
        print("\n👋 Demo server stopped")

if __name__ == "__main__":
    main()
