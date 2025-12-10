#!/bin/sh

# --- Configuration ---
echo "Setting up persistent directories..."

# Use a persistent folder outside the workspace to store the NVD database
DATA_DIRECTORY="/var/lib/jenkins/OWASP-Dependency-Check/data"
REPORT_DIRECTORY="$WORKSPACE/OWASP-Dependency-Check/reports"

mkdir -p "$DATA_DIRECTORY" "$REPORT_DIRECTORY"

# Ensure Jenkins user owns the directories
chown -R $(id -u):$(id -g) "$DATA_DIRECTORY" "$REPORT_DIRECTORY"

# 1. Initialize NVD database only if missing
DB_FILE="$DATA_DIRECTORY/cve.db"

if [ ! -f "$DB_FILE" ]; then
    echo "No NVD database found. Initializing database..."
    docker run --rm \
        -u $(id -u):$(id -g) \
        -v "$DATA_DIRECTORY":/usr/share/dependency-check/data \
        owasp/dependency-check \
        --updateonly
else
    echo "Existing NVD database detected. Skipping full initialization."
fi

# 2. Pull latest Docker image
echo "Pulling latest Dependency Check Docker image..."
docker pull owasp/dependency-check

# 3. Run the scan
echo "--- Running the vulnerability scan ---"
docker run --rm \
    -u $(id -u):$(id -g) \
    -v "$WORKSPACE":/src \
    -v "$DATA_DIRECTORY":/usr/share/dependency-check/data \
    -v "$REPORT_DIRECTORY":/report \
    owasp/dependency-check \
    --scan /src \
    --nvdApiKey "f957fd4e-28e5-4657-b2c2-e60c56e5ceaf" \
    --format ALL \
    --project "My OWASP Dependency Check Project" \
    --out /report
    # Optional suppression:
    # --suppression "/src/security/dependency-check-suppression.xml"

echo "--- Scan Finished ---"
echo "Reports available at $REPORT_DIRECTORY"
