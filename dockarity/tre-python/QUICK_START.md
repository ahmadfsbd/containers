# Quick Start Guide: Containerized Research Environments

## Essential Commands

### 1. Process Package List
```bash
# Clean package list format
cat list.txt | sed 's/^py-//' | sed 's/ arch=None-None-x86_64_v3$//' > clean-packages.txt
```

### 2. Install with UV
```bash
# Add standard packages
uv add $(cat clean-packages.txt | tr '\n' ' ')

# Add custom GitHub packages
uv add git+https://github.com/org/package.git@tag
```

### 3. Build Docker Container
```bash
# Build
docker build -t research-env:latest .

# Test
docker run --rm research-env:latest python3 -c "import pandas; print('OK')"
```

### 4. Convert to Singularity
```bash
# Build SIF
singularity build research-env.sif docker-daemon://research-env:latest

# Test
singularity exec research-env.sif python3 -c "import pandas; print('OK')"
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
```

## Troubleshooting
- **"externally managed environment"** → Set UV environment variables
- **"Python.h not found"** → Install python3-dev
- **Custom packages fail** → Install from Git with `uv add git+...`
- **R packages fail** → Install R system dependencies first

## Success Metrics
- ✅ All packages import successfully
- ✅ Custom GitHub packages working
- ✅ R integration functional
- ✅ Both Docker and Singularity containers tested