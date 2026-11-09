# arkitflow-osm-build

Builds the OpenStreetMap data used by the site analysis of [ArkitFlow](https://arkitflow.com)
(Sun & Shadow Study): two [PMTiles](https://github.com/protomaps/PMTiles) archives of
vector tiles for Indonesia at zoom 14, published together in one release per month.

## Data

- **Source:** OpenStreetMap, via the Geofabrik extract
  [`indonesia-latest.osm.pbf`](https://download.geofabrik.de/asia/indonesia.html)
  (checksum-verified on every build). Both archives come from the same extract.
- **`indonesia-roads.pmtiles`** (≈ 210 MB, see [`schema/indonesia-roads.yml`](schema/indonesia-roads.yml)):
  - `roads` — lines for `highway` = motorway … residential, living_street, service,
    road, track, pedestrian, footway, path, steps, cycleway; attributes `highway`,
    `name`, `oneway`, `lanes`, `width`, `maxspeed`, `surface`, `sidewalk`, `bridge`,
    `tunnel`.
  - `transit` — bus stops, platforms, stations, halts, bus/ferry terminals; attributes
    `highway`, `public_transport`, `railway`, `amenity`, `name`.
- **`indonesia-context.pmtiles`** (≈ 730 MB, see [`schema/indonesia-context.yml`](schema/indonesia-context.yml)):
  - `buildings` — footprints (`building=*` except no / construction / proposed /
    demolished / abandoned); attributes `building`, `building:levels`, `height`, `name`.
  - `landcover` — parks, gardens, pitches, forest, farmland and paddy fields, grass,
    scrub, wetland, sand, cemeteries; attributes `landuse`, `leisure`, `natural`,
    `crop`, `name`.
  - `water` — lakes, ponds, reservoirs, river areas; attributes `natural`, `water`,
    `waterway`, `landuse`, `intermittent`, `name`.
  - `waterways` — river, stream, canal, drain and ditch centre lines (`waterway`,
    `intermittent`, `tunnel`, `name`) and the coastline (`natural=coastline`).
  - `railways` — rail, narrow gauge, light rail, subway, monorail, tram; attributes
    `railway`, `service`, `tunnel`, `bridge`, `name`.
- **Output:** both archives (z14 only, gzip-compressed MVT) and `build-info.json`
  (sizes, checksums, source date) as assets of one GitHub Release. `build.sh` stops if an
  archive reaches 1.5 GiB, well under GitHub's 2 GiB asset limit. The two newest releases
  are kept; [`manifest.json`](manifest.json) (schema 2) names them, the archives each one
  holds and the current one. A new release is listed in the manifest before any old one
  is deleted, and old ones are deleted only after the manifest caches have expired.

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
