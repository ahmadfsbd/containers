#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: validate_offline_bundle.sh /path/to/vep116" >&2
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

need Plugins/AlphaMissense.pm
need Plugins/CADD.pm
need Plugins/REVEL.pm
need Plugins/SpliceAI.pm
need Plugins/dbNSFP.pm
need Plugins/loftee_GRCh38/LoF.pm
need manifest/resources.yaml
need manifest/checksums.sha256

if [ "$missing" -ne 0 ]; then
    exit 1
fi

echo "Plugin bundle has required VEP 116 plugin files."
