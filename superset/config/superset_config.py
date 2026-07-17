import os

#getting secret key from environmental variable - generate a  long random strings as secret key
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "NT9f2osNldMdT71NMZGPVkp20Z64L1gkMDE6VhWn21Q4nv53wpx69yL+")# Store your secret keys in .env file

#Setup metadata db (using postgress)
SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL",
        "postgresql+psycopg2://superset:superset@db:5432/superset"
)
# Redis cache (optional but recommended)
CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 1000,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_URL": "redis://redis:6379/0",
}

# Enable async query execution
CELERY_CONFIG = {
    "broker_url": "redis://redis:6379/0",
    "result_backend": "redis://redis:6379/0",
}

# Allow embedding (iFrame)
HTTP_HEADERS = {"X-Frame-Options": "ALLOWALL"}

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "EMBEDDABLE_CHARTS": True,
}

# Optional: row limit
ROW_LIMIT = 50000
WTF_CSRF_ENABLED = True

# Rate limiter warning
RATELIMIT_STORAGE_URI = "redis://redis:6379/0"



EXTRA_CATEGORICAL_COLOR_SCHEMES = [ {  
	 "id": "FinancialColors",       
         "description": "Colors for financial dashboards",
         "label": "Finance",       
	 "isDefault": False,       
	 "colors": ["#1bd488", "#45828b", "#055b65", "#b2c9c5", "#e0e5e9"]}]
