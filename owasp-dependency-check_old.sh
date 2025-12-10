#!/bin/sh
echo "Creating Temp Directory"
OWASPDC_DIRECTORY=$HOME/OWASP-Dependency-Check
DATA_DIRECTORY="$OWASPDC_DIRECTORY/data"
REPORT_DIRECTORY="$OWASPDC_DIRECTORY/reports"
if [ ! -d "$DATA_DIRECTORY" ]; then
    echo "Initially creating persistent directories"
    mkdir -p "$DATA_DIRECTORY"
    chmod -R 777 "$DATA_DIRECTORY"
    mkdir -p "$REPORT_DIRECTORY"
    chmod -R 777 "$REPORT_DIRECTORY"
fi
# Missing Purge Step
echo "Checking for and running database purge to prevent corruption..."

docker run --rm \
    --volume "$DATA_DIRECTORY":/usr/share/dependency-check/data \
    owasp/dependency-check \
    --purge

echo "Downloading the Image"

# Make sure we are using the latest version
docker pull owasp/dependency-check

echo "vulnerability Scanning"

docker run --rm \
    --volume "`pwd`":/src \
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
