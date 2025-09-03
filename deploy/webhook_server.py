#!/usr/bin/env python3

"""
Simple webhook server for GitHub automated deployments
Listens for GitHub webhooks and triggers deployment script
"""

import os
import sys
import json
import hmac
import hashlib
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs

# Configuration
WEBHOOK_SECRET = os.getenv('WEBHOOK_SECRET', '')
PROJECT_DIR = '/home/danielborrowman/pi5_rag_test'
DEPLOY_SCRIPT = os.path.join(PROJECT_DIR, 'deploy', 'deploy.sh')
PORT = int(os.getenv('WEBHOOK_PORT', '8080'))
LOG_FILE = os.path.join(PROJECT_DIR, 'logs', 'webhook.log')

def log(message):
    """Log messages with timestamp"""
    from datetime import datetime
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_message = f"[{timestamp}] {message}\n"
    print(log_message.strip())
    
    # Also log to file
    try:
        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
        with open(LOG_FILE, 'a') as f:
            f.write(log_message)
    except Exception as e:
        print(f"Failed to write to log file: {e}")

def verify_signature(payload, signature, secret):
    """Verify GitHub webhook signature"""
    if not secret or not signature:
        return False
    
    expected_signature = hmac.new(
        secret.encode('utf-8'),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(f"sha256={expected_signature}", signature)

class WebhookHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Override to use our logging function"""
        log(format % args)
    
    def do_GET(self):
        """Handle GET requests (health check)"""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'Pi5 RAG Webhook Server - OK')
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        """Handle POST requests (webhook)"""
        if self.path != '/webhook':
            self.send_response(404)
            self.end_headers()
            return
        
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            payload = self.rfile.read(content_length)
            
            # Get GitHub signature
            signature = self.headers.get('X-Hub-Signature-256', '')
            event = self.headers.get('X-GitHub-Event', '')
            
            log(f"Received webhook: event={event}, signature_present={bool(signature)}")
            
            # Verify signature if secret is configured
            if WEBHOOK_SECRET and not verify_signature(payload, signature, WEBHOOK_SECRET):
                log("Invalid webhook signature")
                self.send_response(401)
                self.end_headers()
                return
            
            # Parse payload
            try:
                data = json.loads(payload.decode('utf-8'))
            except json.JSONDecodeError:
                log("Invalid JSON payload")
                self.send_response(400)
                self.end_headers()
                return
            
            # Only handle push events to main branch
            if event == 'push':
                ref = data.get('ref', '')
                if ref == 'refs/heads/main':
                    log("Push to main branch detected, triggering deployment...")
                    self.trigger_deployment()
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'status': 'deployment triggered'}).encode())
                else:
                    log(f"Ignoring push to branch: {ref}")
                    self.send_response(200)
                    self.end_headers()
            else:
                log(f"Ignoring event: {event}")
                self.send_response(200)
                self.end_headers()
                
        except Exception as e:
            log(f"Error processing webhook: {str(e)}")
            self.send_response(500)
            self.end_headers()
    
    def trigger_deployment(self):
        """Trigger the deployment script"""
        try:
            log("Starting deployment process...")
            # Run deployment script in background
            subprocess.Popen(
                [DEPLOY_SCRIPT],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                cwd=PROJECT_DIR
            )
            log("Deployment script triggered successfully")
        except Exception as e:
            log(f"Failed to trigger deployment: {str(e)}")

def main():
    """Main function"""
    log("Starting Pi5 RAG Webhook Server...")
    log(f"Listening on port {PORT}")
    log(f"Deployment script: {DEPLOY_SCRIPT}")
    log(f"Webhook secret configured: {'Yes' if WEBHOOK_SECRET else 'No'}")
    
    # Verify deployment script exists
    if not os.path.exists(DEPLOY_SCRIPT):
        log(f"ERROR: Deployment script not found: {DEPLOY_SCRIPT}")
        sys.exit(1)
    
    server = HTTPServer(('', PORT), WebhookHandler)
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log("Shutting down webhook server...")
        server.shutdown()

if __name__ == '__main__':
    main()
