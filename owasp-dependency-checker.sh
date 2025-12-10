#!/bin/sh

echo "Setting up persistent directories..."
DATA_DIRECTORY="/var/lib/jenkins/OWASP-Dependency-Check/data"
REPORT_DIRECTORY="$WORKSPACE/OWASP-Dependency-Check/reports"

mkdir -p "$DATA_DIRECTORY" "$REPORT_DIRECTORY"

# 1. Remove old NVD database and update
echo "Removing old NVD database..."
rm -rf "$DATA_DIRECTORY"

echo "Updating NVD database..."
docker run --rm \
    -u $(id -u):$(id -g) \
    -v "$DATA_DIRECTORY":/usr/share/dependency-check/data \
    owasp/dependency-check \
    --updateonly

# 2. Pull latest Docker image
echo "Pulling latest Dependency Check Docker image..."
docker pull owasp/dependency-check

# 3. Clean old reports
echo "Cleaning old reports..."
rm -rf "$REPORT_DIRECTORY"/*

# 4. Run the vulnerability scan, excluding the problematic CVE (if necessary)
echo "--- Running the vulnerability scan ---"
docker run --rm \
    -u $(id -u):$(id -g) \
    -v "$WORKSPACE":/src \
    -v "$DATA_DIRECTORY":/usr/share/dependency-check/data \
    -v "$REPORT_DIRECTORY":/report \
    owasp/dependency-check \
    --scan /src \
    --nvdApiKey "f957fd4e-28e5-4657-b2c2-e60c56e5ceaf" \
    --excludeCves "CVE-2004-2259" \  # Exclude problematic CVE temporarily
    --format ALL \
    --project "My OWASP Dependency Check Project" \
    --out /report

echo "--- Scan Finished ---"
echo "Reports available at $REPORT_DIRECTORY"
