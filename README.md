# arkitflow-osm-build

Builds the road data used by the site analysis of [ArkitFlow](https://arkitflow.com)
(Sun & Shadow Study → Site tab): roads, footpaths and public-transport stops for
Indonesia, as a single [PMTiles](https://github.com/protomaps/PMTiles) archive of vector
tiles at zoom 14.

## Data

- **Source:** OpenStreetMap, via the Geofabrik extract
  [`indonesia-latest.osm.pbf`](https://download.geofabrik.de/asia/indonesia.html)
  (checksum-verified on every build).
- **Content** (see [`schema/indonesia-roads.yml`](schema/indonesia-roads.yml)):
  - `roads` — lines for `highway` = motorway … residential, living_street, service,
    road, track, pedestrian, footway, path, steps, cycleway; attributes `highway`,
    `name`, `oneway`, `lanes`, `width`, `maxspeed`, `surface`, `sidewalk`, `bridge`,
    `tunnel`.
  - `transit` — bus stops, platforms, stations, halts, bus/ferry terminals; attributes
    `highway`, `public_transport`, `railway`, `amenity`, `name`.
  - Buildings are not included.
- **Output:** `indonesia-roads.pmtiles` (≈ 210 MB, z14 only, gzip-compressed MVT),
  published as a GitHub Release asset. The two newest releases are kept;
  [`manifest.json`](manifest.json) names them and the current one.

## Build

Built monthly by GitHub Actions ([`build.yml`](.github/workflows/build.yml)), on
manual dispatch, and when the build itself changes. Uses only the built-in
`GITHUB_TOKEN`; no secrets. Locally: `bash build.sh` (Java 21+), tools: Geofabrik
download + [planetiler](https://github.com/onthegomap/planetiler) 0.10.2 (Apache-2.0).

## Attribution and licence

Map data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright).

The PMTiles archives published here are a **Derivative Database of OpenStreetMap** and
are made available under the
[Open Database License (ODbL) 1.0](https://opendatacommons.org/licenses/odbl/1-0/).
This repository is the public description of how that derivative is produced, as the
ODbL requires; the archives themselves can be downloaded from the
[Releases](../../releases) page.
