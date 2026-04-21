#!/bin/bash
# Wipe demo data from DocumentDB (prepare for live demo reload)
# Works against local, AKS, or EKS — just set MONGODB_URI
set -euo pipefail

DB_NAME="${DB_NAME:-demodb}"
COLLECTION_NAME="${COLLECTION_NAME:-listings}"
MONGODB_URI="${MONGODB_URI:-mongodb://demo:test@localhost:10260/?tls=true&tlsAllowInvalidCertificates=true}"

echo "=== Wiping demo data ==="
echo "Target: $MONGODB_URI"
echo "Database: $DB_NAME"

mongosh "$MONGODB_URI" --eval "
  use('$DB_NAME');
  db.dropDatabase();
  print('Database dropped: $DB_NAME');
" --quiet

echo "✅ Data wiped. Ready for live demo import."
