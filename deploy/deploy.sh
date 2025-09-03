#!/bin/bash

# Pi5 RAG Production Deployment Script
# This script pulls the latest changes from git and restarts services

set -euo pipefail

# Configuration
PROJECT_DIR="/home/danielborrowman/pi5_rag_test"
LOG_FILE="$PROJECT_DIR/logs/deploy.log"
BACKUP_DIR="$PROJECT_DIR/backup"
SERVICE_NAME="pi5-rag-app"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Main deployment function
deploy() {
    log "Starting deployment process..."
    
    # Change to project directory
    cd "$PROJECT_DIR" || error_exit "Cannot change to project directory"
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        error_exit "Not a git repository"
    fi
    
    # Backup current ChromaDB data
    if [ -d "chroma_storage" ]; then
        log "Backing up ChromaDB data..."
        timestamp=$(date '+%Y%m%d_%H%M%S')
        cp -r chroma_storage "$BACKUP_DIR/chroma_storage_$timestamp" || log "Warning: Backup failed"
    fi
    
    # Get current branch and commit
    current_branch=$(git branch --show-current)
    current_commit=$(git rev-parse HEAD)
    log "Current branch: $current_branch"
    log "Current commit: $current_commit"
    
    # Fetch latest changes
    log "Fetching latest changes..."
    git fetch origin || error_exit "Failed to fetch from origin"
    
    # Check if there are new commits
    remote_commit=$(git rev-parse origin/$current_branch)
    if [ "$current_commit" = "$remote_commit" ]; then
        log "No new commits to deploy. Current commit is up to date."
        return 0
    fi
    
    log "New commits detected. Deploying..."
    
    # Stash any local changes
    if ! git diff-index --quiet HEAD --; then
        log "Stashing local changes..."
        git stash push -m "Auto-stash before deployment $(date)"
    fi
    
    # Pull latest changes
    git pull origin "$current_branch" || error_exit "Failed to pull changes"
    
    # Update virtual environment if requirements.txt changed
    if git diff --name-only "$current_commit" HEAD | grep -q "requirements.txt"; then
        log "requirements.txt changed, updating virtual environment..."
        source .venv/bin/activate
        pip install -r requirements.txt || error_exit "Failed to update dependencies"
    fi
    
    # Copy production environment if it doesn't exist
    if [ ! -f ".env" ] && [ -f ".env.production" ]; then
        log "Copying production environment..."
        cp .env.production .env
    fi
    
    # Restart the service if it exists
    if systemctl --user list-unit-files | grep -q "$SERVICE_NAME"; then
        log "Restarting service: $SERVICE_NAME"
        systemctl --user restart "$SERVICE_NAME" || log "Warning: Failed to restart service"
    fi
    
    new_commit=$(git rev-parse HEAD)
    log "Deployment completed successfully!"
    log "Deployed commit: $new_commit"
    
    # Log deployment to history
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Deployed: $current_commit -> $new_commit" >> "$PROJECT_DIR/logs/deployment_history.log"
}

# Setup logging
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"

# Run deployment
deploy

log "Deployment script completed."
