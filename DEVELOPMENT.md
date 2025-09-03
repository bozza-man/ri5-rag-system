# Development Workflow for Pi5 RAG System

This document explains how to set up and use the development workflow for the Pi5 RAG system.

## Overview

The development workflow allows you to:
- Develop on your local machine
- Automatically sync changes to your Pi5 production system
- Deploy updates with a single command
- Monitor production status remotely

## Quick Start

### 1. Initial Setup

```bash
# Set up development environment
./dev-setup.sh setup

# Configure production server details
export PRODUCTION_HOST="192.168.1.100"  # Your Pi5's IP
export PRODUCTION_USER="pi"              # Your Pi5 username
export PRODUCTION_PATH="/home/pi/ri5-rag-system"
```

### 2. Development Workflow

```bash
# Make your changes to the code
# ...

# Sync changes to production
./dev-setup.sh sync

# Or deploy and restart services
./dev-setup.sh deploy
```

## Development Commands

### Local Development

```bash
# Set up development environment (run once)
./dev-setup.sh setup

# Activate virtual environment
source .venv/bin/activate

# Run demo ingestion (no API key needed)
python -m src.demo_ingest

# Run demo queries
python -m src.demo_query "your question here"

# Run production ingestion (requires OpenAI API key)
python -m src.ingest_chroma

# Run production queries
python -m src.query_chroma "your question here"
```

### Production Sync

```bash
# Sync changes to production
./dev-setup.sh sync

# Pull latest changes from production
./dev-setup.sh pull

# Deploy and restart services
./dev-setup.sh deploy

# Check status
./dev-setup.sh status
```

## Production Setup (on Pi5)

### 1. Initial Production Setup

SSH into your Pi5 and run:

```bash
# Clone the repository
git clone https://github.com/bozza-man/ri5-rag-system.git
cd ri5-rag-system

# Run initial setup
./deploy/production-deploy.sh setup

# Edit production environment
nano .env
```

### 2. Production Commands

```bash
# Deploy updates
./deploy/production-deploy.sh deploy

# Check status
./deploy/production-deploy.sh status

# Restart services
./deploy/production-deploy.sh restart

# View logs
./deploy/production-deploy.sh logs
```

## Automatic Deployment

### GitHub Actions (Recommended)

1. **Set up GitHub Secrets:**
   - Go to your repository settings
   - Add these secrets:
     - `PI5_HOST`: Your Pi5's IP address
     - `PI5_USER`: Your Pi5 username (usually `pi`)
     - `PI5_SSH_KEY`: Your SSH private key

2. **Enable automatic deployment:**
   - Push to `main` branch triggers automatic deployment
   - Or manually trigger via GitHub Actions tab

### Systemd Timer (Alternative)

The production system includes a systemd timer that checks for updates every 5 minutes:

```bash
# Check timer status
sudo systemctl status pi5-rag-deploy.timer

# View timer logs
sudo journalctl -u pi5-rag-deploy.timer
```

## File Structure

```
ri5-rag-system/
├── src/                          # Source code
│   ├── demo_ingest.py           # Demo ingestion (no API key)
│   ├── demo_query.py            # Demo queries
│   ├── ingest_chroma.py         # Production ingestion
│   └── query_chroma.py          # Production queries
├── samples/                      # Sample documents
├── deploy/                       # Deployment scripts
│   └── production-deploy.sh     # Production setup script
├── .github/workflows/            # GitHub Actions
│   └── deploy.yml               # Auto-deployment workflow
├── dev-setup.sh                 # Development workflow script
├── requirements.txt             # Python dependencies
├── .env.example                 # Environment template
├── .env.production              # Production environment template
└── README.md                    # Main documentation
```

## Environment Configuration

### Development (.env)
```bash
# Copy and edit for development
cp .env.example .env
nano .env
```

### Production (.env.production)
```bash
# Production-specific settings
OPENAI_API_KEY=your_production_key
QDRANT_COLLECTION=pi5-production
EMBED_MODEL=text-embedding-3-small
WATCH_DIR=samples
```

## Troubleshooting

### Connection Issues

```bash
# Test SSH connection
ssh pi@192.168.1.100

# Check if services are running
ssh pi@192.168.1.100 "sudo systemctl status pi5-rag-app"
```

### Deployment Issues

```bash
# Check GitHub Actions logs
# Go to your repository → Actions tab

# Check production logs
ssh pi@192.168.1.100 "sudo journalctl -u pi5-rag-app -f"
```

### Development Issues

```bash
# Reset development environment
rm -rf .venv
./dev-setup.sh setup

# Check git status
git status
git log --oneline -5
```

## Best Practices

1. **Always test locally first:**
   ```bash
   source .venv/bin/activate
   python -m src.demo_ingest
   python -m src.demo_query "test question"
   ```

2. **Commit frequently:**
   ```bash
   git add .
   git commit -m "Description of changes"
   ./dev-setup.sh sync
   ```

3. **Monitor production:**
   ```bash
   ./dev-setup.sh status
   ```

4. **Use meaningful commit messages:**
   ```bash
   git commit -m "Add new document processing feature"
   git commit -m "Fix ChromaDB connection issue"
   ```

## Security Notes

- Never commit API keys or sensitive data
- Use environment variables for configuration
- Keep SSH keys secure
- Regularly update dependencies

## Support

If you encounter issues:
1. Check the logs: `./dev-setup.sh status`
2. Verify SSH connection to Pi5
3. Check GitHub Actions for deployment errors
4. Review the production logs on the Pi5
