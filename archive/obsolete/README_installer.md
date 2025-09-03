# Pi5 RAG Installer

A comprehensive installer for setting up a RAG (Retrieval-Augmented Generation) system on Raspberry Pi 5 and other ARM64 systems.

## Files

- **`pi5_rag_test_installer_clean.sh`** - Main installer script (enhanced with error handling, validation, and cross-platform support)
- **`pi5_rag_test_archive.zip`** - Project archive containing all RAG components
- **`pi5_rag_test_installer_fixed.sh`** - Legacy version with embedded archive (for reference)

## Quick Start

1. Ensure both files are in the same directory
2. Make the script executable: `chmod +x pi5_rag_test_installer_clean.sh`
3. Run the installer: `./pi5_rag_test_installer_clean.sh --force`

## Features

### Enhanced Installer Script
- ✅ **Color-coded logging** with success, error, warning, and info messages
- ✅ **Comprehensive error handling** with graceful failure recovery
- ✅ **System validation** (disk space, memory, OS detection, Pi5 hardware detection)
- ✅ **Cross-platform compatibility** (Linux + macOS)
- ✅ **Command-line options** for flexible installation
- ✅ **Post-installation validation** to verify all components
- ✅ **ARM64 compatibility fixes** for Qdrant vector database

### Command Line Options
```bash
-h, --help              Show help message
-d, --dir DIR           Installation directory (default: ./pi5_rag_test)
-s, --skip-validation   Skip system requirements check
-f, --force             Force installation even if directory exists
--no-docker             Skip Docker installation
--no-ingest             Skip sample data ingestion
--dry-run               Preview installation without making changes
```

### Environment Variables
```bash
OPENAI_API_KEY          OpenAI API key for embeddings (optional)
RCLONE_REMOTE           Rclone remote for backup sync (optional)
BATCH_MODE=1            Non-interactive mode
```

## What Gets Installed

1. **Docker & Docker Compose** - Container runtime
2. **Qdrant Vector Database** - ARM64-compatible configuration
3. **Python Virtual Environment** - With all required dependencies
4. **Sample RAG System** - Complete with ingestion and query scripts
5. **Systemd Services** - Optional backup synchronization
6. **Configuration Files** - Environment setup and API key management

## Usage Examples

```bash
# Basic installation
./pi5_rag_test_installer_clean.sh

# Force overwrite existing installation
./pi5_rag_test_installer_clean.sh --force

# Install to custom directory
./pi5_rag_test_installer_clean.sh -d /opt/rag

# Preview installation
./pi5_rag_test_installer_clean.sh --dry-run

# Install with OpenAI API key
OPENAI_API_KEY=sk-... ./pi5_rag_test_installer_clean.sh --force

# Skip Docker installation (if already installed)
./pi5_rag_test_installer_clean.sh --no-docker
```

## Post-Installation

After successful installation:

1. Navigate to the project directory: `cd pi5_rag_test`
2. Activate the virtual environment: `source .venv/bin/activate`
3. Set your OpenAI API key in `.env` file (if not provided during installation)
4. Run sample ingestion: `python -m src.ingest`
5. Test queries: `python -m src.query "your question"`

## Troubleshooting

### Qdrant Container Issues
The installer includes fixes for ARM64 systems with 16KB page sizes. If you encounter issues:
- The script automatically disables jemalloc and uses system malloc
- Uses Qdrant v1.7.4 for better ARM64 compatibility
- Includes memory allocator configuration

### Archive Not Found
Ensure `pi5_rag_test_archive.zip` is in the same directory as the installer script.

## System Requirements

- **Minimum disk space**: 2GB
- **Minimum memory**: 2GB (4GB+ recommended)
- **OS**: Debian/Ubuntu (Raspberry Pi OS), macOS (for development)
- **Architecture**: ARM64 (optimized for Pi5, compatible with other ARM64 systems)

## Version History

- **v2.0** - Enhanced installer with comprehensive error handling, validation, and ARM64 fixes
- **v1.0** - Original embedded installer script

## License

This project is provided as-is for educational and development purposes.
