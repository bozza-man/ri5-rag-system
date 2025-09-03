# Pi5 RAG System Configuration Guide

This guide explains how to configure the Pi5 RAG system with the correct system information for your deployment.

## Quick Configuration Setup

### 1. Interactive Configuration (Recommended)

```bash
# Run the interactive setup
./setup-config.sh --interactive
```

This will guide you through:
- Setting your Pi5's IP address
- Configuring username and paths
- Testing connections
- Creating the configuration file

### 2. Manual Configuration

```bash
# Copy the example configuration
cp config.env.example config.env

# Edit with your system details
nano config.env
```

## Configuration Variables

### Required Settings

| Variable | Description | Example |
|----------|-------------|---------|
| `PRODUCTION_HOST` | Your Pi5's IP address or hostname | `192.168.1.100` |
| `PRODUCTION_USER` | Username on your Pi5 | `pi` |
| `PRODUCTION_PATH` | Deployment path on Pi5 | `/home/pi/ri5-rag-system` |

### Service Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVICE_NAME` | Main systemd service name | `pi5-rag-app` |
| `CHROMA_SERVICE_NAME` | ChromaDB service name | `pi5-rag-chroma` |

### Example Configuration

```bash
# Production Server Configuration
PRODUCTION_HOST=192.168.1.100
PRODUCTION_USER=pi
PRODUCTION_PATH=/home/pi/ri5-rag-system

# Service Configuration
SERVICE_NAME=pi5-rag-app
CHROMA_SERVICE_NAME=pi5-rag-chroma
```

## System Information

### Current System Architecture

Your Pi5 RAG system uses:
- **Vector Database**: ChromaDB (not Qdrant)
- **Python Environment**: Virtual environment with dependencies
- **Service Management**: Systemd services
- **Deployment**: Git-based with automatic updates

### Service Names

The system uses these service names:
- `pi5-rag-app`: Main RAG application service
- `pi5-rag-deploy`: Deployment service
- `pi5-rag-deploy.timer`: Auto-deployment timer

### File Structure

```
/home/pi/ri5-rag-system/          # Production deployment path
├── src/                          # Source code
│   ├── demo_ingest.py           # Demo ingestion (no API key)
│   ├── demo_query.py            # Demo queries
│   ├── ingest_chroma.py         # Production ingestion
│   └── query_chroma.py          # Production queries
├── samples/                      # Sample documents
├── .venv/                        # Python virtual environment
├── .env                          # Environment configuration
└── requirements.txt              # Python dependencies
```

## Configuration Commands

### Check Current Configuration

```bash
# Show current configuration
./dev-setup.sh config

# Validate configuration
./dev-setup.sh validate

# Check configuration with connection tests
./setup-config.sh --check
```

### Update Configuration

```bash
# Interactive configuration update
./setup-config.sh --interactive

# Or edit manually
nano config.env
```

## GitHub Actions Configuration

For automatic deployment, set up these GitHub Secrets:

1. Go to your repository: https://github.com/bozza-man/ri5-rag-system
2. Navigate to Settings → Secrets and variables → Actions
3. Add these secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `PI5_HOST` | Your Pi5's IP address | `192.168.1.100` |
| `PI5_USER` | Pi5 username | `pi` |
| `PI5_SSH_KEY` | SSH private key content | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

## Production Setup

### Initial Production Setup

SSH into your Pi5 and run:

```bash
# Clone the repository
git clone https://github.com/bozza-man/ri5-rag-system.git
cd ri5-rag-system

# Run initial setup
./deploy/production-deploy.sh setup

# Configure environment
cp .env.production .env
nano .env  # Add your OpenAI API key
```

### Production Commands

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

## Development Workflow

### Local Development

```bash
# Set up development environment
./dev-setup.sh setup

# Check configuration
./dev-setup.sh config

# Make changes to code
# ...

# Sync to production
./dev-setup.sh sync

# Deploy and restart
./dev-setup.sh deploy
```

### Testing Connections

```bash
# Test Pi5 connectivity
ping 192.168.1.100

# Test SSH connection
ssh pi@192.168.1.100

# Test service status
ssh pi@192.168.1.100 "sudo systemctl status pi5-rag-app"
```

## Troubleshooting

### Configuration Issues

```bash
# Check configuration
./dev-setup.sh config

# Validate settings
./dev-setup.sh validate

# Test connections
./setup-config.sh --check
```

### Connection Issues

```bash
# Test network connectivity
ping $PRODUCTION_HOST

# Test SSH
ssh $PRODUCTION_USER@$PRODUCTION_HOST

# Check SSH keys
ssh-add -l
```

### Service Issues

```bash
# Check service status on Pi5
ssh pi@192.168.1.100 "sudo systemctl status pi5-rag-app"

# View service logs
ssh pi@192.168.1.100 "sudo journalctl -u pi5-rag-app -f"

# Restart service
ssh pi@192.168.1.100 "sudo systemctl restart pi5-rag-app"
```

## Security Notes

- Never commit `config.env` to git (it's in .gitignore)
- Use SSH key authentication for production access
- Keep your OpenAI API keys secure
- Regularly update dependencies and system packages

## Support

If you encounter issues:

1. Check configuration: `./dev-setup.sh config`
2. Validate settings: `./dev-setup.sh validate`
3. Test connections: `./setup-config.sh --check`
4. Check production logs: `./deploy/production-deploy.sh logs`
5. Review GitHub Actions logs for deployment issues
