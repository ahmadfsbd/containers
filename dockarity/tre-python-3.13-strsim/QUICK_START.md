# Quick Start Guide: TRE Python 3.13 + String Similarity Environment

## Essential Commands

### 1. Process Package List
```bash
# Clean package list format
cat list.txt | sed 's/^py-//' | sed 's/ arch=None-None-x86_64_v3$//' > clean-packages.txt
```

### 2. Install with UV (Python 3.13)
```bash
# Add standard packages
uv add --python 3.13 $(cat clean-packages.txt | tr '\n' ' ')

# Add custom GitHub packages
uv add git+https://github.com/genes-and-health/tre-tools.git@v0.2.0-release
uv add git+https://github.com/brielin/Popcorn.git
uv add git+https://github.com/23andMe/yhaplo.git@2.1.13

# Add string similarity packages
uv add polars-strsim polars-distance rapidfuzz
```

### 3. Build Docker Container
```bash
# Build
docker build -t tre-python-3.13-strsim:latest .

# Test
docker run --rm tre-python-3.13-strsim:latest python3 -c \
  "import polars_strsim, polars_distance, rapidfuzz, pandas, tretools; print('OK')"
```

### 4. Convert to Singularity
```bash
# Build SIF
singularity build tre-python-3.13-strsim.sif docker-daemon://tre-python-3.13-strsim:latest

# Test
singularity exec tre-python-3.13-strsim.sif python3 -c \
  "import polars_strsim, polars_distance, rapidfuzz; print('OK')"
```

## Key Environment Variables
```dockerfile
ENV UV_SYSTEM_PYTHON=1
ENV UV_BREAK_SYSTEM_PACKAGES=1
```

## Common System Dependencies
```bash
# For compiled packages
sudo apt-get install -y python3-dev build-essential

# For R integration
sudo apt-get install -y r-base r-base-dev

# For bioinformatics packages
sudo apt-get install -y libbz2-dev liblzma-dev libhdf5-dev

# For VCF/BCF tools
sudo apt-get install -y bcftools
```

## Regenerating the Lock File
```bash
# Regenerate uv.lock after changes to pyproject.toml
uv lock --python 3.13

# Then rebuild
docker build -t tre-python-3.13-strsim:latest .
```

## Troubleshooting
- **"externally managed environment"** → Set UV environment variables
- **"Python.h not found"** → Install python3-dev
- **Custom packages fail** → Install from Git with `uv add git+...`
- **R packages fail** → Install R system dependencies first
- **String similarity packages fail** → Check polars version compatibility (requires polars>=1.30)

## Success Metrics
- ✅ All packages import successfully
- ✅ Custom GitHub packages working (tretools, popcorn, yhaplo)
- ✅ R integration functional (rpy2)
- ✅ String similarity packages working (polars-strsim, polars-distance, rapidfuzz)
- ✅ Both Docker and Singularity containers tested
