#!/usr/bin/env bash
# Builds dist/indonesia-roads.pmtiles from the Geofabrik Indonesia extract.
#
#   ./build.sh                 # needs Java 21+, curl, md5sum, sha256sum
#
# Output:
#   dist/indonesia-roads.pmtiles   roads, footpaths, transit stops; z14; gzip MVT
#   dist/build-info.json           source timestamp, sizes and checksums
set -euo pipefail

PLANETILER_VERSION="0.10.2"
PLANETILER_SHA256="f310bd0413e2e4512b27f4046d418664e8e1d3bf31603c2a70e23de06c167e4d"
GEOFABRIK_URL="https://download.geofabrik.de/asia/indonesia-latest.osm.pbf"
OUT="dist/indonesia-roads.pmtiles"

cd "$(dirname "$0")"
mkdir -p dl dist work

# 1. planetiler, pinned by version and checksum
JAR="dl/planetiler-${PLANETILER_VERSION}.jar"
if [ ! -f "$JAR" ]; then
  curl -fsSL --retry 3 -o "$JAR" \
    "https://github.com/onthegomap/planetiler/releases/download/v${PLANETILER_VERSION}/planetiler.jar"
fi
echo "${PLANETILER_SHA256}  ${JAR}" | sha256sum -c -

# 2. OSM extract, verified against Geofabrik's published md5
PBF="dl/indonesia-latest.osm.pbf"
curl -fsSL --retry 3 -o "${PBF}.md5" "${GEOFABRIK_URL}.md5"
curl -fsSL --retry 3 -R -o "$PBF" "$GEOFABRIK_URL"
EXPECTED_MD5="$(cut -d' ' -f1 "${PBF}.md5")"
echo "${EXPECTED_MD5}  ${PBF}" | md5sum -c -
# Geofabrik's Last-Modified (kept by curl -R) is the extract's data timestamp.
SOURCE_DATE="$(date -u -r "$PBF" +%Y-%m-%dT%H:%M:%SZ)"

# 3. tiles
java -Xmx8g -jar "$JAR" generate-custom \
  --schema=schema/indonesia-roads.yml \
  --osm_path="$PBF" \
  --output="$OUT" \
  --tmpdir=work/tmp \
  --minzoom=14 --maxzoom=14 \
  --force

# 4. build info (read by the workflow to write manifest.json)
BYTES="$(stat -c %s "$OUT")"
SHA256="$(sha256sum "$OUT" | cut -d' ' -f1)"
cat > dist/build-info.json <<JSON
{
  "asset": "$(basename "$OUT")",
  "bytes": ${BYTES},
  "sha256": "${SHA256}",
  "source": "${GEOFABRIK_URL}",
  "source_md5": "${EXPECTED_MD5}",
  "source_date": "${SOURCE_DATE}",
  "planetiler": "${PLANETILER_VERSION}",
  "schema": "schema/indonesia-roads.yml",
  "built_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
cat dist/build-info.json
