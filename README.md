# Pi5 RAG System

A production-ready RAG (Retrieval-Augmented Generation) system optimized for ARM64 systems like Raspberry Pi 5.

## Features

- **ARM64 Compatible**: Uses ChromaDB instead of Qdrant for vector storage
- **Document Processing**: Supports PDF, TXT, and Markdown files  
- **Semantic Search**: Vector-based similarity search
- **Production Ready**: Automated deployment and service management
- **Scalable**: Easy to add more documents and scale processing

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Documents     │───▶│   Processing     │───▶│  Vector Store   │
│  (PDF/TXT/MD)   │    │  (Text Extract   │    │   (ChromaDB)    │
│                 │    │   + Chunking)    │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│    Results      │◀───│   Query Engine   │◀───│   User Query    │
│  (Ranked Docs)  │    │  (Similarity     │    │                 │
│                 │    │   Search)        │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Quick Start

### Development Mode (Demo)
```bash
# Install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Ingest documents (demo mode - no API key needed)
python -m src.demo_ingest

# Query documents  
python -m src.demo_query "your question here"
```

### Production Mode (with OpenAI)
```bash
# Set up environment
cp .env.example .env
# Edit .env with your OpenAI API key

# Ingest documents
python -m src.ingest_chroma

# Query documents
python -m src.query_chroma "your question here"
```

## Deployment

This system is configured for automated deployment from GitHub:

```bash
# Deploy latest changes
sudo systemctl restart pi5-rag-deploy
sudo systemctl restart pi5-rag-app

# Check status
sudo systemctl status pi5-rag-app
```

## File Structure

```
pi5_rag_test/
├── src/
│   ├── demo_ingest.py      # Demo ingestion (no API key)
│   ├── demo_query.py       # Demo queries
│   ├── ingest_chroma.py    # Production ingestion
│   └── query_chroma.py     # Production queries
├── samples/                # Sample documents
├── deploy/                 # Deployment scripts
├── systemd/               # Service configurations
├── requirements.txt       # Python dependencies
├── docker-compose.yml     # Container configuration
└── README.md              # This file
```

## Adding Documents

1. Add your documents to the `samples/` directory
2. Run ingestion: `python -m src.demo_ingest` or `python -m src.ingest_chroma`
3. Query your documents: `python -m src.demo_query "question"`

## System Requirements

- **OS**: Linux (Debian/Ubuntu recommended)
- **Architecture**: ARM64 (optimized for Pi5)
- **Memory**: 2GB+ recommended
- **Storage**: 1GB+ for document storage
- **Python**: 3.11+

## Configuration

Environment variables (in `.env`):
- `OPENAI_API_KEY`: OpenAI API key for embeddings
- `QDRANT_COLLECTION`: Collection name (default: pi5-smoketest)
- `EMBED_MODEL`: Embedding model (default: text-embedding-3-small)
- `WATCH_DIR`: Directory to watch for documents (default: samples)

## License

MIT License - see LICENSE file for details.
