#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-.}"
ARCHIVE_BASE="${2:-large-files}"
CHUNK_SIZE="${3:-95M}"

cd "$REPO_ROOT"

echo "Finding files > 100MB under prebuilts/ ..."
find prebuilts -type f -size +100M > /tmp/_large_files.txt
COUNT=$(wc -l < /tmp/_large_files.txt)

if [ "$COUNT" -eq 0 ]; then
  echo "No large files found."
  rm -f /tmp/_large_files.txt
  exit 0
fi

echo "Found $COUNT files."

# Create uncompressed tar
echo "Creating tar archive ..."
tar -cf "/tmp/${ARCHIVE_BASE}.tar" -T /tmp/_large_files.txt

# Split into chunks
echo "Splitting into ${CHUNK_SIZE} chunks ..."
split -b "$CHUNK_SIZE" "/tmp/${ARCHIVE_BASE}.tar" "${ARCHIVE_BASE}.part."
rm -f "/tmp/${ARCHIVE_BASE}.tar"

# Create checksum
echo "Creating checksums ..."
md5sum "${ARCHIVE_BASE}.part."* > "${ARCHIVE_BASE}.md5"

# Remove original large files
echo "Removing original large files ..."
xargs rm -f < /tmp/_large_files.txt

# Clean up empty parent dirs (remove dirs that became empty after deletion)
find prebuilts -type d -empty -delete 2>/dev/null || true

rm -f /tmp/_large_files.txt

# Add to .gitignore
if [ -f .gitignore ]; then
  if ! grep -qxF 'prebuilts/' .gitignore; then
    echo '' >> .gitignore
    echo '# Large prebuilt files (packed as chunks)' >> .gitignore
    echo 'prebuilts/' >> .gitignore
  fi
else
  echo '# Large prebuilt files (packed as chunks)' > .gitignore
  echo 'prebuilts/' >> .gitignore
fi

echo "Done: $(ls ${ARCHIVE_BASE}.part.* | wc -l) parts created"
du -h "${ARCHIVE_BASE}.part."*
