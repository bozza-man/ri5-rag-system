#!/usr/bin/env bash
# Production Deployment Script for Pi5 RAG System
# This script should be run on the Pi5 to set up automatic deployment

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

log() { echo -e "${BOLD}[prod-deploy]${RESET} $1" >&2; }
log_success() { echo -e "${GREEN}✓${RESET} $1" >&2; }
log_error() { echo -e "${RED}✗${RESET} $1" >&2; }
log_warning() { echo -e "${YELLOW}⚠${RESET} $1" >&2; }

# Configuration
REPO_URL="https://github.com/bozza-man/ri5-rag-system.git"
DEPLOY_PATH="/home/pi/ri5-rag-system"
SERVICE_NAME="pi5-rag-app"

setup_production() {
    log "Setting up production deployment..."
    
    # Clone repository if it doesn't exist
    if [ ! -d "$DEPLOY_PATH" ]; then
        log "Cloning repository..."
        git clone "$REPO_URL" "$DEPLOY_PATH"
        log_success "Repository cloned"
    else
        log "Repository already exists, updating..."
        cd "$DEPLOY_PATH"
        git pull origin main
        log_success "Repository updated"
    fi
    
    # Set up Python environment
    cd "$DEPLOY_PATH"
    if [ ! -d ".venv" ]; then
        log "Creating Python virtual environment..."
        python3 -m venv .venv
        log_success "Virtual environment created"
    fi
    
    # Install dependencies
    log "Installing dependencies..."
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    log_success "Dependencies installed"
    
    # Set up environment
    if [ ! -f ".env" ]; then
        log "Setting up production environment..."
        cp .env.production .env
        log_warning "Please edit .env file with your production settings"
        log_success "Production environment created"
    fi
    
    # Set up systemd service
    setup_systemd_service
    
    log_success "Production setup complete!"
}

setup_systemd_service() {
    log "Setting up systemd service..."
    
    # Create systemd service file
    sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=Pi5 RAG System
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=${DEPLOY_PATH}
Environment=PATH=${DEPLOY_PATH}/.venv/bin
ExecStart=${DEPLOY_PATH}/.venv/bin/python -m src.demo_query
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Create deployment service
    sudo tee /etc/systemd/system/pi5-rag-deploy.service > /dev/null << EOF
[Unit]
Description=Pi5 RAG Deployment Service
After=network.target

[Service]
Type=oneshot
User=pi
WorkingDirectory=${DEPLOY_PATH}
ExecStart=/bin/bash -c 'cd ${DEPLOY_PATH} && git pull origin main && source .venv/bin/activate && pip install -r requirements.txt'
EOF

    # Create deployment timer
    sudo tee /etc/systemd/system/pi5-rag-deploy.timer > /dev/null << EOF
[Unit]
Description=Pi5 RAG Auto-Deploy Timer
Requires=pi5-rag-deploy.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Reload systemd and enable services
    sudo systemctl daemon-reload
    sudo systemctl enable ${SERVICE_NAME}
    sudo systemctl enable pi5-rag-deploy.timer
    sudo systemctl start pi5-rag-deploy.timer
    
    log_success "Systemd services configured"
}

deploy_update() {
    log "Deploying update..."
    
    cd "$DEPLOY_PATH"
    
    # Pull latest changes
    git pull origin main
    
    # Update dependencies
    source .venv/bin/activate
    pip install -r requirements.txt
    
    # Restart service
    sudo systemctl restart ${SERVICE_NAME}
    
    # Check status
    sudo systemctl status ${SERVICE_NAME} --no-pager
    
    log_success "Deployment complete!"
}

show_status() {
    log "Production Status:"
    echo ""
    
    # Service status
    log "Service Status:"
    sudo systemctl status ${SERVICE_NAME} --no-pager
    echo ""
    
    # Deployment timer status
    log "Auto-deploy Timer Status:"
    sudo systemctl status pi5-rag-deploy.timer --no-pager
    echo ""
    
    # Repository status
    log "Repository Status:"
    cd "$DEPLOY_PATH"
    git status --short
    echo ""
    git log --oneline -3
}

show_help() {
    cat << EOF
Pi5 RAG Production Deployment

Usage: $0 [COMMAND]

Commands:
  setup           Initial production setup
  deploy          Deploy latest changes
  status          Show production status
  restart         Restart services
  logs            Show service logs
  help            Show this help message

Examples:
  $0 setup        # Initial setup (run once)
  $0 deploy       # Deploy latest changes
  $0 status       # Check system status
EOF
}

main() {
    case "${1:-help}" in
        setup)
            setup_production
            ;;
        deploy)
            deploy_update
            ;;
        status)
            show_status
            ;;
        restart)
            sudo systemctl restart ${SERVICE_NAME}
            log_success "Service restarted"
            ;;
        logs)
            sudo journalctl -u ${SERVICE_NAME} -f
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
