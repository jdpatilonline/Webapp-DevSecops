#!/bin/sh

# --- Configuration ---
echo "Setting up persistent directories..."

OWASPDC_DIRECTORY=$HOME/OWASP-Dependency-Check
DATA_DIRECTORY="$OWASPDC_DIRECTORY/data"
REPORT_DIRECTORY="$OWASPDC_DIRECTORY/reports"

# 1. Directory Check and Setup
mkdir -p "$DATA_DIRECTORY" "$REPORT_DIRECTORY"
chmod -R 777 "$OWASPDC_DIRECTORY"

# 2. Database Maintenance — only purge if DB missing or corrupted
DB_FILE="$DATA_DIRECTORY/cve.db"

if [ ! -f "$DB_FILE" ]; then
    echo "No NVD database found. Running purge to initialize database..."
    docker run --rm \
        -v "$DATA_DIRECTORY":/usr/share/dependency-check/data \
        owasp/dependency-check \
        --purge
else
    echo "Existing NVD database detected. Skipping purge."
fi

# 3. Pull the Latest Docker Image
echo "Downloading the latest Dependency Check Docker image..."
docker pull owasp/dependency-check

# 4. Perform Scan
echo "--- Running the vulnerability scan ---"

docker run --rm \
    -v "$(pwd)":/src \
    -v "$DATA_DIRECTORY":/usr/share/dependency-check/data \
    -v "$REPORT_DIRECTORY":/report \
    owasp/dependency-check \
    --scan /src \
    --nvdApiKey "f957fd4e-28e5-4657-b2c2-e60c56e5ceaf" \
    --format "ALL" \
    --project "My OWASP Dependency Check Project" \
    --out /report

echo "--- Scan Finished ---"
