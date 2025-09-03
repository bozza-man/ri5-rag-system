#!/bin/bash

# Pi5 RAG Management Script
# Easy commands to manage the production deployment

set -euo pipefail

PROJECT_DIR="/home/danielborrowman/pi5_rag_test"
cd "$PROJECT_DIR"

case "${1:-help}" in
    "deploy")
        echo "🚀 Triggering manual deployment..."
        ./deploy/deploy.sh
        ;;
    
    "status")
        echo "📊 System Status:"
        echo "=================="
        echo "📦 Git Status:"
        git status --short || echo "Not a git repository"
        echo ""
        echo "🐳 Services:"
        systemctl --user status pi5-rag-webhook.service --no-pager --lines=3 || echo "Webhook service not running"
        echo ""
        systemctl --user status pi5-rag-deploy.timer --no-pager --lines=3 || echo "Deploy timer not running"
        echo ""
        echo "📋 Recent deployments:"
        tail -5 logs/deployment_history.log 2>/dev/null || echo "No deployment history"
        ;;
    
    "logs")
        case "${2:-deploy}" in
            "webhook")
                echo "📜 Webhook logs:"
                journalctl --user -u pi5-rag-webhook.service -n 20 --no-pager
                ;;
            "deploy")
                echo "📜 Deployment logs:"
                tail -50 logs/deploy.log 2>/dev/null || echo "No deployment logs"
                ;;
            *)
                echo "Usage: $0 logs [webhook|deploy]"
                ;;
        esac
        ;;
    
    "start")
        echo "▶️  Starting services..."
        systemctl --user start pi5-rag-webhook.service
        systemctl --user start pi5-rag-deploy.timer
        echo "✅ Services started"
        ;;
    
    "stop")
        echo "⏹️  Stopping services..."
        systemctl --user stop pi5-rag-webhook.service
        systemctl --user stop pi5-rag-deploy.timer
        echo "✅ Services stopped"
        ;;
    
    "restart")
        echo "🔄 Restarting services..."
        systemctl --user restart pi5-rag-webhook.service
        systemctl --user restart pi5-rag-deploy.timer
        echo "✅ Services restarted"
        ;;
    
    "test")
        echo "🧪 Testing RAG system..."
        source .venv/bin/activate
        echo "Testing demo ingestion..."
        python -m src.demo_ingest
        echo ""
        echo "Testing demo query..."
        python -m src.demo_query "network incident"
        ;;
    
    "backup")
        echo "💾 Creating backup..."
        timestamp=$(date '+%Y%m%d_%H%M%S')
        backup_dir="backup/manual_backup_$timestamp"
        mkdir -p "$backup_dir"
        
        # Backup ChromaDB
        if [ -d "chroma_storage" ]; then
            cp -r chroma_storage "$backup_dir/"
            echo "✅ ChromaDB data backed up"
        fi
        
        # Backup logs
        if [ -d "logs" ]; then
            cp -r logs "$backup_dir/"
            echo "✅ Logs backed up"
        fi
        
        echo "✅ Backup created: $backup_dir"
        ;;
    
    "setup-github")
        echo "🔗 GitHub setup instructions:"
        echo "================================"
        echo "1. Create a new repository on GitHub"
        echo "2. Add this remote:"
        echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
        echo ""
        echo "3. Push initial code:"
        echo "   git push -u origin main"
        echo ""
        echo "4. Set up webhook (optional):"
        echo "   - Go to Settings > Webhooks in your GitHub repo"
        echo "   - Add webhook: http://YOUR_SERVER_IP:8080/webhook"
        echo "   - Content type: application/json"
        echo "   - Secret: (set in .env as WEBHOOK_SECRET)"
        echo "   - Events: Just the push event"
        echo ""
        echo "5. Update .env with your OpenAI API key for production mode"
        ;;
    
    "health")
        echo "🏥 Health check..."
        echo "==================="
        
        # Check if services are running
        if systemctl --user is-active --quiet pi5-rag-webhook.service; then
            echo "✅ Webhook service: Running"
        else
            echo "❌ Webhook service: Stopped"
        fi
        
        # Check webhook endpoint
        if curl -s http://localhost:8080/health > /dev/null 2>&1; then
            echo "✅ Webhook endpoint: Responding"
        else
            echo "❌ Webhook endpoint: Not responding"
        fi
        
        # Check ChromaDB storage
        if [ -d "chroma_storage" ]; then
            echo "✅ ChromaDB storage: Present"
        else
            echo "⚠️  ChromaDB storage: Not found (run ingestion)"
        fi
        
        # Check virtual environment
        if [ -d ".venv" ]; then
            echo "✅ Virtual environment: Present"
        else
            echo "❌ Virtual environment: Missing"
        fi
        ;;
    
    "help"|*)
        echo "🛠️  Pi5 RAG Management Commands"
        echo "=================================="
        echo "deploy          - Run manual deployment"
        echo "status          - Show system status"
        echo "logs [type]     - Show logs (webhook|deploy)"
        echo "start           - Start all services"
        echo "stop            - Stop all services"  
        echo "restart         - Restart all services"
        echo "test            - Test the RAG system"
        echo "backup          - Create manual backup"
        echo "setup-github    - Show GitHub setup instructions"
        echo "health          - Run health checks"
        echo "help            - Show this help"
        echo ""
        echo "Examples:"
        echo "  ./deploy/manage.sh deploy"
        echo "  ./deploy/manage.sh logs webhook"
        echo "  ./deploy/manage.sh test"
        ;;
esac
