#!/bin/sh

# --- Configuration ---
echo "Setting up persistent directories in Jenkins workspace..."

# Use Jenkins workspace instead of /var/lib/jenkins
OWASPDC_DIRECTORY="$WORKSPACE/OWASP-Dependency-Check"
DATA_DIRECTORY="$OWASPDC_DIRECTORY/data"
REPORT_DIRECTORY="$OWASPDC_DIRECTORY/reports"

# Create directories if they don't exist
mkdir -p "$DATA_DIRECTORY" "$REPORT_DIRECTORY"

# No need to chmod if ownership is correct in workspace

# 2. Database Maintenance — only purge if DB missing
DB_FILE="$DATA_DIRECTORY/cve.db"

if [ ! -f "$DB_FILE" ]; then
    echo "No NVD database found. Initializing database..."
    docker run --rm \
        -u $(id -u):$(id -g) \
        -v "$DATA_DIRECTORY":/usr/share/dependency-check/data \
        owasp/dependency-check \
        --purge
else
    echo "Existing NVD database detected. Skipping purge."
fi

# 3. Pull latest Docker image
echo "Pulling latest Dependency Check Docker image..."
docker pull owasp/dependency-check

# 4. Run the scan
echo "--- Running the vulnerability scan ---"

docker run --rm \
    -u $(id -u):$(id -g) \
    -v "$WORKSPACE":/src \
    -v "$DATA_DIRECTORY":/usr/share/dependency-check/data \
    -v "$REPORT_DIRECTORY":/report \
    owasp/dependency-check \
    --scan /src \
    --nvdApiKey "f957fd4e-28e5-4657-b2c2-e60c56e5ceaf" \
    --format "ALL" \
    --project "My OWASP Dependency Check Project" \
    --out /report
    # Optional suppression:
    # --suppression "/src/security/dependency-check-suppression.xml"

echo "--- Scan Finished ---"
echo "Reports available at $REPORT_DIRECTORY"
