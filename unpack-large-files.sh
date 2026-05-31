#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-.}"
ARCHIVE_BASE="${2:-large-files}"

cd "$REPO_ROOT"

# Check for split parts
PARTS=( "${ARCHIVE_BASE}.part."* )
if [ ${#PARTS[@]} -eq 0 ]; then
  echo "No split parts found (${ARCHIVE_BASE}.part.*)"
  exit 1
fi

# Verify checksums
if [ -f "${ARCHIVE_BASE}.md5" ]; then
  echo "Verifying checksums ..."
  md5sum -c "${ARCHIVE_BASE}.md5"
fi

# Recombine and extract
echo "Recombining and extracting ..."
cat "${ARCHIVE_BASE}.part."* | tar -xf -

echo "Done"
