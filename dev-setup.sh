#!/usr/bin/env bash
# Development Setup Script for Pi5 RAG System
# This script sets up the development environment and syncs with production

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

log() { echo -e "${BOLD}[dev-setup]${RESET} $1" >&2; }
log_success() { echo -e "${GREEN}✓${RESET} $1" >&2; }
log_info() { echo -e "${BLUE}ℹ${RESET} $1" >&2; }
log_warning() { echo -e "${YELLOW}⚠${RESET} $1" >&2; }

# Load configuration
if [ -f "config.env" ]; then
    source config.env
    log_info "Loaded configuration from config.env"
fi

# Configuration with defaults
REPO_URL="https://github.com/bozza-man/ri5-rag-system.git"
PRODUCTION_HOST="${PRODUCTION_HOST:-pi5.local}"  # Change this to your Pi5's hostname/IP
PRODUCTION_USER="${PRODUCTION_USER:-pi}"         # Change this to your Pi5 username
PRODUCTION_PATH="${PRODUCTION_PATH:-/home/pi/ri5-rag-system}"
SERVICE_NAME="${SERVICE_NAME:-pi5-rag-app}"

validate_config() {
    log "Validating configuration..."
    
    # Check if config file exists
    if [ ! -f "config.env" ]; then
        log_warning "No config.env file found. Using defaults."
        log_info "Copy config.env.example to config.env and customize for your setup"
        return 0
    fi
    
    # Validate required settings
    if [ "$PRODUCTION_HOST" = "pi5.local" ]; then
        log_warning "Using default hostname 'pi5.local'. Update config.env with your Pi5's IP"
    fi
    
    if [ "$PRODUCTION_USER" = "pi" ]; then
        log_info "Using default username 'pi'"
    fi
    
    log_success "Configuration validated"
}

show_help() {
    cat << EOF
Pi5 RAG Development Setup

Usage: $0 [COMMAND]

Commands:
  setup           Set up development environment
  sync            Sync changes to production
  pull            Pull latest changes from production
  status          Show git status and sync status
  deploy          Deploy to production and restart services
  config          Show current configuration
  validate        Validate configuration
  help            Show this help message

Configuration:
  Copy config.env.example to config.env and customize:
  - PRODUCTION_HOST: Your Pi5's IP address (e.g., 192.168.1.100)
  - PRODUCTION_USER: Username on Pi5 (usually 'pi')
  - PRODUCTION_PATH: Deployment path (default: /home/pi/ri5-rag-system)

Examples:
  $0 setup                    # Initial development setup
  $0 sync                     # Push changes to production
  $0 pull                     # Pull latest from production
  $0 config                   # Show current configuration
  $0 validate                 # Validate configuration
EOF
}

setup_dev_environment() {
    log "Setting up development environment..."
    
    # Create virtual environment
    if [ ! -d ".venv" ]; then
        log "Creating Python virtual environment..."
        python3 -m venv .venv
        log_success "Virtual environment created"
    else
        log_success "Virtual environment already exists"
    fi
    
    # Activate and install dependencies
    log "Installing Python dependencies..."
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    log_success "Dependencies installed"
    
    # Create development .env file
    if [ ! -f ".env" ]; then
        log "Creating development .env file..."
        cp .env.example .env
        log_info "Edit .env file with your OpenAI API key for full functionality"
        log_success "Development .env created"
    else
        log_success "Development .env already exists"
    fi
    
    log_success "Development environment ready!"
    log_info "Activate with: source .venv/bin/activate"
}

sync_to_production() {
    log "Syncing changes to production..."
    
    # Push to GitHub
    log "Pushing changes to GitHub..."
    git add .
    git commit -m "Development changes: $(date)" || log_info "No changes to commit"
    git push origin main
    log_success "Changes pushed to GitHub"
    
    # Pull on production server
    log "Pulling changes on production server..."
    ssh "${PRODUCTION_USER}@${PRODUCTION_HOST}" "cd ${PRODUCTION_PATH} && git pull origin main"
    log_success "Changes pulled on production server"
}

pull_from_production() {
    log "Pulling latest changes from production..."
    
    # Pull from GitHub
    git pull origin main
    log_success "Latest changes pulled from GitHub"
    
    # Update dependencies if requirements.txt changed
    if git diff HEAD~1 HEAD --name-only | grep -q requirements.txt; then
        log "Requirements changed, updating dependencies..."
        source .venv/bin/activate
        pip install -r requirements.txt
        log_success "Dependencies updated"
    fi
}

show_status() {
    log "Development Status:"
    echo ""
    
    # Git status
    log_info "Git Status:"
    git status --short
    echo ""
    
    # Remote status
    log_info "Remote Status:"
    git log --oneline -5
    echo ""
    
    # Production connection test
    log_info "Production Connection:"
    if ssh -o ConnectTimeout=5 "${PRODUCTION_USER}@${PRODUCTION_HOST}" "echo 'Connected'" 2>/dev/null; then
        log_success "Production server reachable"
    else
        log_info "Production server not reachable (check PRODUCTION_HOST setting)"
    fi
}

deploy_to_production() {
    log "Deploying to production..."
    
    # Sync changes
    sync_to_production
    
    # Restart services on production
    log "Restarting services on production..."
    ssh "${PRODUCTION_USER}@${PRODUCTION_HOST}" "cd ${PRODUCTION_PATH} && sudo systemctl restart ${SERVICE_NAME}"
    log_success "Services restarted on production"
    
    # Check service status
    log "Checking service status..."
    ssh "${PRODUCTION_USER}@${PRODUCTION_HOST}" "sudo systemctl status ${SERVICE_NAME} --no-pager"
}

show_config() {
    log "Current Configuration:"
    echo ""
    echo "Production Host: $PRODUCTION_HOST"
    echo "Production User: $PRODUCTION_USER"
    echo "Production Path: $PRODUCTION_PATH"
    echo "Service Name: $SERVICE_NAME"
    echo "Repository URL: $REPO_URL"
    echo ""
    if [ -f "config.env" ]; then
        log_success "Configuration loaded from config.env"
    else
        log_warning "No config.env file found, using defaults"
        log_info "Run: cp config.env.example config.env"
    fi
}

main() {
    case "${1:-help}" in
        setup)
            validate_config
            setup_dev_environment
            ;;
        sync)
            validate_config
            sync_to_production
            ;;
        pull)
            pull_from_production
            ;;
        status)
            show_status
            ;;
        deploy)
            validate_config
            deploy_to_production
            ;;
        config)
            show_config
            ;;
        validate)
            validate_config
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
