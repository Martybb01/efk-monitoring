#!/usr/bin/env python3
"""
Simple Flask App for EFK testing with structured logging
"""

import json
import time
import threading
from datetime import datetime
from flask import Flask, jsonify

app = Flask(__name__)

def log_json(level, message, **extra):
    """Helper function to log structured JSON"""
    log_entry = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "level": level,
        "component": "flask-app",
        "message": message
    }
    log_entry.update(extra)
    print(json.dumps(log_entry))

@app.route('/')
def index():
    log_json("INFO", "Root endpoint accessed", endpoint="/")
    return jsonify({
        'message': 'Simple Flask App for EFK testing',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat() + "Z"
    })

@app.route('/health')
def health():
    log_json("INFO", "Health check requested", endpoint="/health")
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat() + "Z"
    })

@app.route('/api/data')
def data():
    random_num = int(time.time()) % 1000
    log_json("INFO", "Data endpoint accessed", endpoint="/api/data", generated_number=random_num)
    return jsonify({
        'data': random_num,
        'message': 'Sample data generated',
        'timestamp': datetime.utcnow().isoformat() + "Z"
    })

@app.route('/api/error')
def error():
    log_json("ERROR", "Test error endpoint accessed", endpoint="/api/error", error_type="test_error")
    return jsonify({
        'error': 'Test error for logging',
        'timestamp': datetime.utcnow().isoformat() + "Z"
    }), 500

def background_logger():
    """Generate periodic log entries for testing"""
    while True:
        time.sleep(60)  # Log every minute
        log_json("INFO", "Periodic background log", background_task=True, uptime_minutes=int(time.time() - start_time) // 60)

if __name__ == '__main__':
    start_time = time.time()
    
    log_json("INFO", "Flask application starting", 
             port=5001, 
             environment="development")
    
    background_thread = threading.Thread(target=background_logger, daemon=True)
    background_thread.start()
    log_json("INFO", "Background logging thread started")
    
    app.run(host='0.0.0.0', port=5001, debug=False)