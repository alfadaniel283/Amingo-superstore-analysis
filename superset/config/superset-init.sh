#!/bin/bash
set -e

echo ">>>Runing DB migrations..............."
superset db upgrade

echo ">>>Creating Admin User................"
superset fab create-admin \
  --username admin \
  --firstname Admin \
  --lastname User \
  --email admin@superset.com \
  --password admin


echo ">>> Initializing roles and permission........."
superset init

echo ">>> Loading Example data"
superset load_examples

echo ">>> Superset init Complete. open localhost:8088"
