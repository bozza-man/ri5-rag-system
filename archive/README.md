# Archived Files

This directory contains files that are no longer used in the current Pi5 RAG system but are kept for reference and historical purposes.

## Archived Files

### Obsolete Installer Files
- **`pi5_rag_test_installer_clean.sh`** - Original enhanced installer script (replaced by dev-setup.sh)
- **`pi5_rag_test_archive.zip`** - Embedded project archive (replaced by direct git repository)
- **`pi5_rag_test.zip`** - Duplicate project archive
- **`README_installer.md`** - Installer-specific documentation (replaced by DEVELOPMENT.md)

### Obsolete Docker Configuration
- **`docker-compose.yml`** - Qdrant-based Docker configuration (system now uses ChromaDB)
- **`docker-compose.yml.backup`** - Backup of Docker configuration

### Obsolete System Files
- **`systemd/`** - Qdrant-specific systemd services (not needed for ChromaDB system)
  - `qdrant-snapshot-sync.service` - Qdrant snapshot sync service
  - `qdrant-snapshot-sync.timer` - Qdrant snapshot sync timer
- **`install_pi5.sh`** - Original installation script (replaced by deploy/production-deploy.sh)

### Development Artifacts
- **`.mypy_cache/`** - Python type checking cache
- **`.DS_Store`** - macOS system file

## Why These Files Are Archived

### System Architecture Change
The system was originally designed to use Qdrant as the vector database, but the production system uses ChromaDB instead. This change made several files obsolete:

1. **Docker Compose Files**: Qdrant-specific configuration
2. **Systemd Services**: Qdrant snapshot synchronization
3. **Installer Scripts**: Embedded archive approach replaced by git-based deployment

### Development Workflow Evolution
The development workflow evolved from a single installer script to a comprehensive development environment:

1. **Single Script → Multiple Scripts**: Replaced monolithic installer with specialized scripts
2. **Embedded Archive → Git Repository**: Moved from embedded files to proper git workflow
3. **Manual Setup → Automated Deployment**: Added GitHub Actions and systemd timers

## Current System Architecture

The current system uses:
- **Vector Database**: ChromaDB (local, no Docker required)
- **Development Workflow**: Git-based with automated deployment
- **Service Management**: Systemd services for the Python application
- **Deployment**: GitHub Actions + systemd timers

## If You Need These Files

These files are kept for reference in case you need to:
- Understand the original system design
- Revert to Qdrant-based architecture
- Reference the original installer approach
- Debug migration issues

## File Locations

- **Current Development Scripts**: `dev-setup.sh`, `setup-config.sh`
- **Current Production Scripts**: `deploy/production-deploy.sh`
- **Current Documentation**: `DEVELOPMENT.md`, `CONFIGURATION.md`
- **Current System**: ChromaDB-based RAG system in `src/`

## Archive Date

Files archived on: $(date)
Reason: System migration from Qdrant to ChromaDB and development workflow improvements
