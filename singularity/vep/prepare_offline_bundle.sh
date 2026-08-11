#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage:
  prepare_offline_bundle.sh OUT_DIR

Downloads only VEP plugin code for the VEP 116 TRE bundle.

This script downloads plugin code only.

Example:
  ./prepare_offline_bundle.sh /data/staging/vep116
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

if [ "$#" -ne 1 ]; then
    usage >&2
    exit 2
fi

OUT_DIR=$1
KEEP_SOURCE_ARCHIVES=${KEEP_SOURCE_ARCHIVES:-0}

mkdir -p "$OUT_DIR"/{manifest,source_archives,Plugins}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cp "$SCRIPT_DIR/resources.yaml" "$OUT_DIR/manifest/resources.yaml"

fetch() {
    local url=$1
    local dest=$2
    mkdir -p "$(dirname "$dest")"
    if [ -s "$dest" ]; then
        printf 'exists: %s\n' "$dest"
        return
    fi
    printf 'download: %s\n' "$url"
    curl -L --fail --retry 5 --continue-at - --output "$dest" "$url"
}

extract_tar_strip1() {
    local archive=$1
    local dest=$2
    mkdir -p "$dest"
    tar -xzf "$archive" --strip-components=1 -C "$dest"
}

need_plugin() {
    local path=$1
    if [ ! -s "$OUT_DIR/$path" ]; then
        printf 'error: expected plugin file missing after download: %s\n' "$path" >&2
        exit 1
    fi
}

if [ ! -s "$OUT_DIR/Plugins/AlphaMissense.pm" ]; then
    fetch \
        "https://github.com/Ensembl/VEP_plugins/archive/refs/heads/release/116.tar.gz" \
        "$OUT_DIR/source_archives/VEP_plugins_release_116.tar.gz"
    extract_tar_strip1 "$OUT_DIR/source_archives/VEP_plugins_release_116.tar.gz" "$OUT_DIR/Plugins"
fi

if [ ! -s "$OUT_DIR/Plugins/loftee_GRCh38/LoF.pm" ]; then
    fetch \
        "https://github.com/konradjk/loftee/archive/refs/heads/grch38.tar.gz" \
        "$OUT_DIR/source_archives/loftee_GRCh38.tar.gz"
    extract_tar_strip1 "$OUT_DIR/source_archives/loftee_GRCh38.tar.gz" "$OUT_DIR/Plugins/loftee_GRCh38"
fi

need_plugin Plugins/AlphaMissense.pm
need_plugin Plugins/CADD.pm
need_plugin Plugins/REVEL.pm
need_plugin Plugins/SpliceAI.pm
need_plugin Plugins/dbNSFP.pm
need_plugin Plugins/loftee_GRCh38/LoF.pm

if [ "$KEEP_SOURCE_ARCHIVES" != "1" ]; then
    find "$OUT_DIR/source_archives" -type f -delete
    rmdir "$OUT_DIR/source_archives" 2>/dev/null || true
fi

find "$OUT_DIR" -type f ! -path "$OUT_DIR/manifest/checksums.sha256" -print0 | sort -z | xargs -0 sha256sum > "$OUT_DIR/manifest/checksums.sha256"

printf '\nPlugin code staged at: %s\n' "$OUT_DIR"
printf 'Checksums: %s\n' "$OUT_DIR/manifest/checksums.sha256"
