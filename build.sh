#!/usr/bin/env bash
# Builds the two PMTiles archives of one release from the Geofabrik Indonesia extract.
#
#   ./build.sh                 # needs Java 21+, curl, jq, md5sum, sha256sum
#
# Output:
#   dist/indonesia-roads.pmtiles     roads, footpaths, transit stops (schema/indonesia-roads.yml)
#   dist/indonesia-context.pmtiles   buildings, land cover, water, railways (schema/indonesia-context.yml)
#   dist/build-info.json             source timestamp, and size + checksum per archive
#
# Both archives are z14 only, gzip MVT, built from the same extract.
set -euo pipefail

PLANETILER_VERSION="0.10.2"
PLANETILER_SHA256="f310bd0413e2e4512b27f4046d418664e8e1d3bf31603c2a70e23de06c167e4d"
GEOFABRIK_URL="https://download.geofabrik.de/asia/indonesia-latest.osm.pbf"
# GitHub refuses release assets of 2 GiB or more; fail well before that.
MAX_ASSET_BYTES=$((1536 * 1024 * 1024))
# archive id → schema; the asset is dist/indonesia-<id>.pmtiles
ARCHIVES=(roads context)

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

# 3. tiles, one archive per schema
ARCHIVES_JSON="{}"
for ID in "${ARCHIVES[@]}"; do
  OUT="dist/indonesia-${ID}.pmtiles"
  SCHEMA="schema/indonesia-${ID}.yml"
  START="$(date +%s)"
  java -Xmx8g -jar "$JAR" generate-custom \
    --schema="$SCHEMA" \
    --osm_path="$PBF" \
    --output="$OUT" \
    --tmpdir=work/tmp \
    --minzoom=14 --maxzoom=14 \
    --force
  SECONDS_TAKEN=$(( $(date +%s) - START ))
  BYTES="$(stat -c %s "$OUT")"
  if [ "$BYTES" -ge "$MAX_ASSET_BYTES" ]; then
    echo "::error::${OUT} is ${BYTES} bytes, above the ${MAX_ASSET_BYTES}-byte safety limit" >&2
    exit 1
  fi
  ARCHIVES_JSON="$(jq -c \
    --arg id "$ID" --arg asset "$(basename "$OUT")" --arg schema "$SCHEMA" \
    --arg sha "$(sha256sum "$OUT" | cut -d' ' -f1)" \
    --argjson bytes "$BYTES" --argjson secs "$SECONDS_TAKEN" \
    '. + {($id): {asset: $asset, bytes: $bytes, sha256: $sha, schema: $schema, build_seconds: $secs}}' \
    <<<"$ARCHIVES_JSON")"
  rm -rf work/tmp
done

# 4. build info (read by the workflow to write manifest.json)
jq -n \
  --arg source "$GEOFABRIK_URL" --arg md5 "$EXPECTED_MD5" --arg date "$SOURCE_DATE" \
  --arg planetiler "$PLANETILER_VERSION" --arg built "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson archives "$ARCHIVES_JSON" \
  '{source: $source, source_md5: $md5, source_date: $date, planetiler: $planetiler,
    built_at: $built, archives: $archives}' > dist/build-info.json
cat dist/build-info.json
