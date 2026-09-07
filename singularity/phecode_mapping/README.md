# PhecodeX Mapper Singularity And Release Bundle

This folder contains:

- `singularity.def` for building the PhecodeX mapper image, with R added
- `prepare_offline_bundle.sh` for downloading and verifying the analyst bundle
- `validate_offline_bundle.sh` for checking a staged bundle
- `resources.yaml` recording the release the bundle came from

The image and the mapping release are handled separately. The image carries the
mapper code and its pinned dependencies; it carries no map and no cohort data.

## What Upstream Ships

[phecode_mapping](https://github.com/astheeggeggs/phecode_mapping) is an
installable Python package, `phecodex-mapper`, exposing one entry point,
`phecodex-map`, plus analyst and maintainer helper scripts in Python and R.

The upstream repository does not need to go into the TRE. Releases are
distributed as a self-contained analyst bundle carrying the mapper source, the
pinned lockfile, the upstream container definitions and the mapping release. The
only thing the git repository adds is the pytest suite, which the bundle does not
ship. Clone it on a build host if you want to run the tests.

Upstream ships `containers/Singularity.def` and `containers/Dockerfile`.
`singularity.def` here is that definition plus R, for the reason below.

## Why This Definition Adds R

The upstream base is `python:3.11-slim`, which has no R interpreter, but two of
the scripts the bundle ships are R:

- `scripts/prepare_ukb_for_mapping.R` - turns a UK Biobank wide phenotype extract
  into the canonical cohort and events pair the mapper consumes
- `scripts/deidentify_ukb_for_testing.R`

Upstream copies both into the image, where they are present but unrunnable. For
UK Biobank that removes the entry point to the workflow, since the wide extract
has to be reshaped before `phecodex-map run` will accept it. `data.table` is
their only R dependency and Debian packages it, so it comes from apt rather than
being compiled from CRAN.

## Stage The Bundle

Run on an internet-connected machine. Stage to `./bundle`, which is where
`singularity.def` reads its `%files` from:

```bash
cd singularity/phecode_mapping
./prepare_offline_bundle.sh ./bundle
```

This downloads the release tarball, checks it against its published `.sha256`
sidecar, extracts it, and writes a checksum manifest.

```text
./bundle/
  pyproject.toml
  requirements-lock.txt
  src/phecodex_mapper/
  scripts/
  examples/
  release/               <- the map; bind read-only at run time
    manifest.json
    icd_map.parquet
    ...
  manifest/
    resources.yaml
    checksums.sha256
```

Check a staged bundle with:

```bash
./validate_offline_bundle.sh ./bundle
python3 bundle/scripts/verify_release.py --release bundle/release
```

Both are worth running: `validate_offline_bundle.sh` checks the expected files are
present, while `verify_release.py` re-hashes every shipped file against the digests
in `release/manifest.json` and refuses a release carrying an unrecorded file the
mapper would read. Neither replaces the `.sha256` check the staging script does,
which is the only one that tells you the download arrived intact and was the
bundle you were meant to have.

## Build Singularity Image

```bash
cd singularity/phecode_mapping
singularity build phecodex-mapper_0.1.0.sif singularity.def
```

The build needs network access, for the base image and for pip and apt, so it
happens outside the TRE. Transfer the resulting `.sif` in. Mapping itself runs
fully offline - there are no network calls anywhere in the mapper.

`0.1.0` is the **mapper's** version, not a PhecodeX version. Do not tag an image
`1.1`: the image carries no map at all, and the release bound into it is a hybrid
of PhecodeX 1.1 (ICD-10-CM) and 1.0 (WHO ICD-10). Which PhecodeX versions a run
used is recorded in the release's `manifest.json` under
`phecodex_upstream_versions`, and nowhere else.

## Place In TRE

Two artefacts, staged separately:

| Artefact | Size | Destination |
|---|---|---|
| `phecodex-mapper_0.1.0.sif` | 182 MB | Image storage |
| `bundle/release/` | 23 MB | Secure storage, bind read-only |

Upload the release under the versioned bucket prefix:

```text
gs://qmul-production-library-red/helper-files-and-scripts/phecodex/v1.1cm-1.0who-icd-only/
```

Keep the prefix versioned rather than writing to a bare `phecodex/` folder, so
that a later release does not overwrite the one existing runs were mapped against.

## Run

Verify the release before mapping against it:

```bash
singularity run phecodex-mapper_0.1.0.sif \
    python /opt/phecodex/scripts/verify_release.py --release /data/release
```

Reshape a UK Biobank wide extract, inside the secure environment:

```bash
singularity run phecodex-mapper_0.1.0.sif \
    Rscript /opt/phecodex/scripts/prepare_ukb_for_mapping.R \
        --input ukb_extract.tsv \
        --cohort-out cohort.csv.gz --events-out events.csv.gz \
        --female-code 0 --male-code 1
```

Validate inputs without mapping, then map:

```bash
singularity exec --containall \
    --bind /secure/release:/data/release:ro \
    --bind /secure/input:/data/input:ro \
    --bind /secure/output:/data/output \
    phecodex-mapper_0.1.0.sif \
    phecodex-map run --release /data/release \
        --cohort /data/input/cohort.csv \
        --events /data/input/events.csv \
        --output /data/output/phecodex_run --preflight-only
```

Drop `--preflight-only` to map. `run` refuses to overwrite an existing output
directory. Budget about 16 GB of memory for a 500,000-person cohort.

Bind only what a run needs, and never bind individual-level data or generated
cohort outputs into a build.

## Two Things That Fail Silently

**UK Biobank codes WHO `ICD10`, not `ICD10CM`.** The `vocabulary` column is taken
as ground truth, so the wrong label does not error - the codes simply do not match
and the events are dropped into `unmapped_events.csv`. The two maps differ in both
directions, and for 163 codes present in both the wrong label yields a *different*
phenotype rather than none. `prepare_ukb_for_mapping.R` emits the right label.

Do not judge this by the unmapped rate: the WHO map is genuinely coarse, so a
correctly labelled UK Biobank extract already sits near 20% unmapped. The field
that discriminates is `share_of_unmapped_rescued_by_sibling` in `audit.json` -
near 1% when correctly labelled, near 20% when mislabelled.

**Exclusion files must not have blank cells.** A blank does not break its own rule
quietly, it makes the exclusion question undecidable for every phecode and empties
every output. A run refuses the file instead, which is the last point at which the
problem is still visible.

Phenotype exclusions are applied by default, whether or not you ask: `run` drops a
bundled recommended set. See
`src/phecodex_mapper/data/recommended_exclusions.csv` in the bundle for exactly
what that does.
