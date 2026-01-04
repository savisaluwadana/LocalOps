from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import psycopg2
import redis
import os
import time

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'app_requests_total',
    'Total app requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'app_request_latency_seconds',
    'Request latency in seconds',
    ['endpoint']
)

# Database connection
def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        database=os.environ.get('DB_NAME', 'myapp'),
        user=os.environ.get('DB_USER', 'postgres'),
        password=os.environ.get('DB_PASSWORD', 'password')
    )

# Redis connection
def get_redis():
    return redis.Redis(
        host=os.environ.get('REDIS_HOST', 'localhost'),
        port=int(os.environ.get('REDIS_PORT', 6379)),
        decode_responses=True
    )

@app.before_request
def before_request():
    from flask import request, g
    g.start_time = time.time()

@app.after_request
def after_request(response):
    from flask import request, g
    latency = time.time() - g.start_time
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.path,
        status=response.status_code
    ).inc()
    REQUEST_LATENCY.labels(endpoint=request.path).observe(latency)
    return response

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/')
def index():
    return jsonify({
        "status": "healthy",
        "app": "localops-demo",
        "version": os.environ.get('APP_VERSION', '1.0.0')
    })

@app.route('/health')
def health():
    return jsonify({"status": "ok"})

@app.route('/ready')
def ready():
    # Check database
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT 1')
        cur.close()
        conn.close()
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 503
    
    return jsonify({"status": "ready"})

@app.route('/users')
def get_users():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT id, username, email, created_at FROM users;')
        users = cur.fetchall()
        cur.close()
        conn.close()
        
        return jsonify([
            {"id": u[0], "username": u[1], "email": u[2], "created_at": str(u[3])}
            for u in users
        ])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/cache/<key>')
def get_cache(key):
    r = get_redis()
    value = r.get(key)
    if value:
        return jsonify({"key": key, "value": value, "cached": True})
    return jsonify({"key": key, "value": None, "cached": False}), 404

@app.route('/cache/<key>/<value>', methods=['POST'])
def set_cache(key, value):
    r = get_redis()
    r.set(key, value, ex=300)  # 5 minute expiry
    return jsonify({"key": key, "value": value, "ttl": 300})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=os.environ.get('DEBUG', 'false').lower() == 'true')
