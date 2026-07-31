import multiprocessing
import os

# Production Gunicorn configuration file for HER AREA Django REST Engine
bind = "0.0.0.0:" + os.environ.get("PORT", "8000")
workers = multiprocessing.cpu_count() * 2 + 1
threads = 2
worker_class = "gthread"
timeout = 60
keepalive = 5
max_requests = 1000
max_requests_jitter = 100

# Logging formatting and paths
loglevel = "info"
errorlog = "-"
accesslog = "-"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(L)s s'
preload_app = True

def on_starting(server):
    server.log.info("Starting HER AREA Marketplace Gunicorn WSGI Server...")
