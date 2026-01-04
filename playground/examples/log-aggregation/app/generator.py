import socket
import json
import time
import random
import os

LOGSTASH_HOST = os.environ.get('LOGSTASH_HOST', 'localhost')
LOGSTASH_PORT = int(os.environ.get('LOGSTASH_PORT', 5000))

log_levels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']
endpoints = ['/api/users', '/api/products', '/api/orders', '/health', '/']
methods = ['GET', 'POST', 'PUT', 'DELETE']

def send_log(log_data):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((LOGSTASH_HOST, LOGSTASH_PORT))
        sock.sendall((json.dumps(log_data) + '\n').encode())
        sock.close()
    except Exception as e:
        print(f"Failed to send log: {e}")

def generate_log():
    level = random.choices(log_levels, weights=[10, 50, 20, 15, 5])[0]
    endpoint = random.choice(endpoints)
    method = random.choice(methods)
    response_time = random.randint(10, 500)
    status = random.choices([200, 201, 400, 404, 500], weights=[70, 10, 10, 5, 5])[0]

    return {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "level": level,
        "service": "log-generator",
        "endpoint": endpoint,
        "method": method,
        "status_code": status,
        "response_time_ms": response_time,
        "message": f"{method} {endpoint} returned {status} in {response_time}ms"
    }

if __name__ == "__main__":
    print(f"Sending logs to {LOGSTASH_HOST}:{LOGSTASH_PORT}")
    
    while True:
        log = generate_log()
        send_log(log)
        print(f"Sent: {log['message']}")
        time.sleep(random.uniform(0.5, 2.0))
