# Building Containerized Research Environments with UV, Docker, and Singularity

This guide demonstrates how to create reproducible research environments by converting a list of Python dependencies into both Docker and Singularity containers using `uv` for fast, reliable package management.

## Overview

This workflow enables you to:
- Start with a simple list of Python package dependencies
- Install all packages (including custom GitHub packages) using `uv`
- Create reproducible Docker containers
- Convert to Singularity SIF files for HPC environments
- Achieve 100% package installation success with proper dependency resolution

## Prerequisites

- Docker installed and running
- Singularity/Apptainer installed
- `uv` package manager installed
- A list of Python package dependencies

## Step-by-Step Guide

### 1. Prepare Your Dependency List

Start with a list of Python packages. Your list can be in various formats:

```txt
# Example: Simple package names
pandas
numpy
scipy
matplotlib
scikit-learn
tensorflow

# Example: With version constraints
pandas==2.3.0
numpy==2.1.3
scipy==1.15.3

# Example: Custom packages from GitHub
git+https://github.com/org/repo.git@v1.0.0
```

### 2. Initialize UV Project

```bash
# Create a new project directory
mkdir my-research-env
cd my-research-env

# Initialize uv project
uv init

# Add packages from your list
uv add $(cat your-packages.txt | tr '\n' ' ')
```

**Pro Tip**: For large package lists, process them in batches to identify and resolve issues:

```bash
# Convert package list format if needed
cat your-packages.txt | sed 's/^py-//' | sed 's/ arch=None-None-x86_64_v3$//' > clean-packages.txt

# Add packages with error handling
uv add $(cat clean-packages.txt | tr '\n' ' ')
```

### 3. Handle Custom Packages

For packages not available on PyPI (custom/internal packages), add them directly from Git:

```bash
# Add custom packages from GitHub
uv add git+https://github.com/org/package.git@v1.0.0
uv add git+https://github.com/org/another-package.git

# Example from our workflow:
uv add git+https://github.com/genes-and-health/tre-tools.git@v0.2.0-release
uv add git+https://github.com/brielin/Popcorn.git
uv add git+https://github.com/23andMe/yhaplo.git@2.1.13
```

### 4. Handle System Dependencies

Some packages require system-level dependencies. Identify and install them:

```bash
# Example: R for rpy2
sudo apt-get update
sudo apt-get install -y r-base r-base-dev

# Example: Python development headers for compiled packages
sudo apt-get install -y python3-dev build-essential
```

### 5. Create Dockerfile

Create a `Dockerfile` that builds on a suitable base image and installs your environment:

```dockerfile
FROM your-base-image:tag

# Set environment variables for system-wide installation
ENV UV_SYSTEM_PYTHON=1
ENV UV_BREAK_SYSTEM_PACKAGES=1

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-dev \
        build-essential \
        r-base \
        r-base-dev \
        # Add other system dependencies as needed
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install uv if not in base image
RUN pip install uv || echo "uv already installed"

# Set working directory
WORKDIR /app

# Copy project files
COPY pyproject.toml uv.lock ./

# Export dependencies and install
RUN uv export --format requirements.txt > requirements.txt
RUN uv pip sync requirements.txt

# Verify installation
RUN python3 -c "import sys; print(f'Python: {sys.version}')" && \
    python3 -c "import key_package1, key_package2; print('✅ Key packages imported')"

# Set entrypoint
ENTRYPOINT ["/bin/bash"]
CMD ["-l"]
```

### 6. Create .dockerignore

Optimize build context by excluding unnecessary files:

```dockerignore
# Virtual environments
.venv/
venv/
__pycache__/
*.pyc

# Git
.git/
.gitignore

# IDE files
.vscode/
.idea/

# OS files
.DS_Store
Thumbs.db

# Build artifacts
build/
dist/
*.egg-info/

# Documentation (keep README)
*.md
!README.md
```

### 7. Build Docker Container

```bash
# Build the container
docker build -t my-research-env:latest .

# Test the container
docker run --rm my-research-env:latest python3 -c "
import sys
print(f'Python: {sys.version}')
# Test your key packages
import pandas, numpy
print('✅ Environment ready!')
"
```

### 8. Convert to Singularity SIF

```bash
# Build Singularity container from Docker image
singularity build my-research-env.sif docker-daemon://my-research-env:latest

# Test Singularity container
singularity exec my-research-env.sif python3 -c "
import sys
print(f'Python: {sys.version}')
# Test your key packages
import pandas, numpy
print('✅ Singularity environment ready!')
"
```

## Troubleshooting Common Issues

### Package Installation Failures

**Issue**: Package fails to install due to missing dependencies
```bash
# Solution: Install system dependencies
sudo apt-get install -y python3-dev build-essential

# For specific packages:
# rpy2 → r-base r-base-dev
# pysam → libbz2-dev liblzma-dev
# h5py → libhdf5-dev
```

**Issue**: Custom packages not found on PyPI
```bash
# Solution: Install from Git repositories
uv add git+https://github.com/org/package.git@tag
```

### Docker Build Issues

**Issue**: "externally managed environment" error
```bash
# Solution: Set environment variables in Dockerfile
ENV UV_SYSTEM_PYTHON=1
ENV UV_BREAK_SYSTEM_PACKAGES=1
```

**Issue**: Python command not found
```bash
# Solution: Use python3 instead of python
RUN python3 -c "import sys; print(sys.version)"
```

### Singularity Issues

**Issue**: Container won't start
```bash
# Solution: Override entrypoint for testing
singularity exec --entrypoint=/bin/bash my-research-env.sif -c "python3 --version"
```

## Best Practices

### 1. Package Management
- Use `uv` for fast, reliable dependency resolution
- Pin versions in `pyproject.toml` for reproducibility
- Handle custom packages explicitly from Git sources
- Test package imports after installation

### 2. Container Optimization
- Use multi-stage builds for smaller images
- Minimize layers by combining RUN commands
- Use `.dockerignore` to reduce build context
- Clean up package caches and temporary files

### 3. Environment Variables
- Set `UV_SYSTEM_PYTHON=1` for system-wide installation
- Set `UV_BREAK_SYSTEM_PACKAGES=1` to bypass restrictions
- Use appropriate base images for your use case

### 4. Testing and Validation
- Test all critical packages after installation
- Verify both Docker and Singularity containers
- Include health checks for production deployments
- Document package versions and sources

## Example Workflow Summary

```bash
# 1. Start with package list
cat > packages.txt << EOF
pandas
numpy
scipy
matplotlib
scikit-learn
tensorflow
git+https://github.com/org/custom-package.git
EOF

# 2. Initialize project
uv init
uv add $(cat packages.txt | tr '\n' ' ')

# 3. Build Docker container
docker build -t research-env:latest .

# 4. Convert to Singularity
singularity build research-env.sif docker-daemon://research-env:latest

# 5. Test both containers
docker run --rm research-env:latest python3 -c "import pandas; print('Docker OK')"
singularity exec research-env.sif python3 -c "import pandas; print('Singularity OK')"
```


## Performance Tips

1. **Use uv for fast package installation** - significantly faster than pip
2. **Leverage Docker layer caching** - order Dockerfile commands from least to most frequently changing
3. **Use .dockerignore** - reduce build context size
4. **Consider multi-stage builds** - separate build and runtime dependencies
5. **Optimize base image selection** - choose minimal base images when possible

## Conclusion

This workflow provides a robust, reproducible method for creating containerized research environments. By using `uv` for package management, Docker for development and testing, and Singularity for HPC deployment, you can ensure consistent environments across different computing platforms.

The key advantages of this approach:
- **Reproducibility**: Exact package versions and dependencies
- **Portability**: Works across different systems and platforms
- **Scalability**: Easy deployment to clusters and cloud environments
- **Maintainability**: Clear dependency management and version control

## Resources

- [UV Documentation](https://docs.astral.sh/uv/)
- [Docker Documentation](https://docs.docker.com/)
- [Singularity Documentation](https://docs.sylabs.io/)
- [Python Packaging User Guide](https://packaging.python.org/)

---

*This guide is based on real-world experience building research environments with 178+ Python packages, including custom GitHub packages and R integration.*