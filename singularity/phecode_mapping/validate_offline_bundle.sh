#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: validate_offline_bundle.sh /path/to/phecodex-bundle" >&2
    exit 2
fi

BUNDLE=$1
missing=0

need() {
    if [ ! -s "$BUNDLE/$1" ]; then
        echo "missing: $1" >&2
        missing=1
    fi
}

# Mapper code, needed to build the image.
need pyproject.toml
need requirements-lock.txt
need src/phecodex_mapper/cli.py
need src/phecodex_mapper/data/recommended_exclusions.csv

# Scripts. The two R ones are why this image adds R to the upstream definition.
need scripts/verify_release.py
need scripts/prepare_ukb_for_mapping.R

# Mapping release, bind-mounted read-only at run time.
need release/manifest.json
need release/icd_map.csv
need release/icd_map.parquet
need release/phecode_info.csv
need release/phecode_info.parquet
need release/phecodex_reference_maps.xlsx
need release/phetk_custom_map_icd10.csv
need release/phetk_custom_map_icd10cm.csv
need release/recovered_codes.csv

need manifest/resources.yaml
need manifest/checksums.sha256

if [ "$missing" -ne 0 ]; then
    exit 1
fi

echo "Bundle has required PhecodeX mapper files and release artifacts."
echo "Now re-hash the release against its own manifest:"
echo "  python3 $BUNDLE/scripts/verify_release.py --release $BUNDLE/release"
