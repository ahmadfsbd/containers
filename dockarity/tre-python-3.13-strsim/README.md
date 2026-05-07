# TRE Python 3.13 + String Similarity Environment

Docker container built on `mercury/softpack-build:0.21.1.2` using `uv` for fast, reproducible package installation.

Extends the base TRE Python 3.13 environment with string similarity packages:
- `polars-strsim` — string similarity functions for Polars DataFrames
- `polars-distance` — distance metrics for Polars DataFrames
- `rapidfuzz` — fast fuzzy string matching

A `/opt/view/bin/python3.13` symlink is created so external Jupyter `.sqfs` overlays can locate the Python executable.

## Build

```bash
docker build -t tre-python-3.13-strsim:latest .
```

## Test

```bash
docker run --rm tre-python-3.13-strsim:latest python3 -c \
  "import polars_strsim, polars_distance, rapidfuzz, pandas, tretools; print('OK')"
```

## Convert to Singularity

```bash
singularity build tre-python-3.13-strsim.sif docker-daemon://tre-python-3.13-strsim:latest
```

## Key Design Decisions

| Feature | Detail |
|---------|--------|
| Base image | `mercury/softpack-build:0.21.1.2` |
| Python | 3.13 via `uv python install`, isolated in `/opt/venv` |
| Package manager | `uv` — resolves from `pyproject.toml` |
| Softpack symlink | `/opt/view/bin/python3.13 → /opt/venv/bin/python3.13` |
| Jupyter kernel | Registered as `python3.13-strsim` via `ipykernel` |

## Custom Packages (from Git)

| Package | Source |
|---------|--------|
| `tretools` | github.com/genes-and-health/tre-tools @ v0.2.0-release |
| `popcorn` | github.com/brielin/Popcorn |
| `yhaplo` | github.com/23andMe/yhaplo @ 2.1.13 |
</content>
</invoke>