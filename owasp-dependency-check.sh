#!/bin/sh
#
# --- Configuration ---
echo "Setting up persistent directories..."
#
# Define persistent directories
OWASPDC_DIRECTORY="$HOME/OWASP-Dependency-Check"
DATA_DIRECTORY="$OWASPDC_DIRECTORY/data"
REPORT_DIRECTORY="$OWASPDC_DIRECTORY/reports"
#
# 1. Directory Check and Setup
if [ ! -d "$DATA_DIRECTORY" ]; then
    echo "Persistent data directory not found. Creating $DATA_DIRECTORY"
    mkdir -p "$DATA_DIRECTORY"
    chmod -R 777 "$DATA_DIRECTORY"
fi

if [ ! -d "$REPORT_DIRECTORY" ]; then
    echo "Persistent report directory not found. Creating $REPORT_DIRECTORY"
    mkdir -p "$REPORT_DIRECTORY"
    chmod -R 777 "$REPORT_DIRECTORY"
fi

# 2. Database Maintenance (Purge)
# Note: If the directory already exists, this step uses the Docker tool 
# to clean up any incompatible or corrupt database files.
echo "Checking for and running database purge to prevent corruption..."

docker run --rm \
    --volume "$DATA_DIRECTORY":/usr/share/dependency-check/data \
    owasp/dependency-check \
    --purge

# 3. Download Latest Docker Image
echo "Downloading the latest Dependency Check Docker image..."
docker pull owasp/dependency-check

# 4. Running the Scanning
echo "--- Running the vulnerability scan ---"

docker run --rm \
    --volume $(pwd):/src \
    --volume "$DATA_DIRECTORY":/usr/share/dependency-check/data \
    --volume "$REPORT_DIRECTORY":/report \
    owasp/dependency-check \
    --scan /src \
    --nvdApiKey "f957fd4e-28e5-4657-b2c2-e60c56e5ceaf" \
    --format "ALL" \
    --project "My OWASP Dependency Check Project" \
    --out /report
    # Use suppression like this: (/src == $pwd)
    # --suppression "/src/security/dependency-check-suppression.xml"

echo "--- Scan Finished ---"
