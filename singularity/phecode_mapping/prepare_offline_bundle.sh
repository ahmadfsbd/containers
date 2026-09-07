#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage:
  prepare_offline_bundle.sh OUT_DIR

Downloads and verifies the PhecodeX analyst bundle for the TRE.

The bundle is self-contained: it carries the mapper source, the pinned lockfile and
the mapping release. The upstream git repository is not needed. OUT_DIR receives the
extracted bundle, with the release under OUT_DIR/release.

Stage to ./bundle before building the image - singularity.def reads its %files from
there:
  ./prepare_offline_bundle.sh ./bundle

Override the release with:
  PHECODEX_RELEASE_TAG=... PHECODEX_RELEASE_ASSET=... ./prepare_offline_bundle.sh OUT_DIR

Example:
  ./prepare_offline_bundle.sh /data/staging/phecodex
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

RELEASE_TAG=${PHECODEX_RELEASE_TAG:-v1.1cm-1.0who-icd-only}
RELEASE_ASSET=${PHECODEX_RELEASE_ASSET:-phecodex-cm1.1-who1.0-icd-only.tar.gz}
BASE_URL=https://github.com/astheeggeggs/phecode_mapping/releases/download/${RELEASE_TAG}

mkdir -p "$OUT_DIR"/{manifest,source_archives}

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

ARCHIVE="$OUT_DIR/source_archives/$RELEASE_ASSET"
CHECKSUM="$OUT_DIR/source_archives/$RELEASE_ASSET.sha256"

if [ ! -s "$OUT_DIR/release/manifest.json" ]; then
    fetch "$BASE_URL/$RELEASE_ASSET" "$ARCHIVE"
    fetch "$BASE_URL/$RELEASE_ASSET.sha256" "$CHECKSUM"

    # The sidecar answers a different question from verify_release.py: that the
    # download arrived intact and is the bundle that was published, rather than that
    # the release matches its own internal manifest. Check both.
    printf 'verify: %s\n' "$RELEASE_ASSET"
    ( cd "$OUT_DIR/source_archives" && sha256sum -c "$RELEASE_ASSET.sha256" )

    # strip-components=1 drops the phecodex-distribution/ wrapper so that OUT_DIR is
    # itself the bundle root, which is what singularity.def and the README assume.
    tar -xzf "$ARCHIVE" --strip-components=1 -C "$OUT_DIR"
fi

need_file() {
    local path=$1
    if [ ! -s "$OUT_DIR/$path" ]; then
        printf 'error: expected bundle file missing after download: %s\n' "$path" >&2
        exit 1
    fi
}

need_file pyproject.toml
need_file requirements-lock.txt
need_file src/phecodex_mapper/cli.py
need_file scripts/verify_release.py
need_file scripts/prepare_ukb_for_mapping.R
need_file release/manifest.json
need_file release/icd_map.parquet
need_file release/phecode_info.parquet

if [ "$KEEP_SOURCE_ARCHIVES" != "1" ]; then
    find "$OUT_DIR/source_archives" -type f -delete
    rmdir "$OUT_DIR/source_archives" 2>/dev/null || true
fi

find "$OUT_DIR" -type f ! -path "$OUT_DIR/manifest/checksums.sha256" -print0 | sort -z | xargs -0 sha256sum > "$OUT_DIR/manifest/checksums.sha256"

printf '\nBundle staged at: %s\n' "$OUT_DIR"
printf 'Release (bind read-only at run time): %s/release\n' "$OUT_DIR"
printf 'Checksums: %s/manifest/checksums.sha256\n' "$OUT_DIR"
