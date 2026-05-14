FROM mercury/softpack-build:0.21.1.2

# Python 3.13 + String Similarity Research Environment Container
# This container includes:
# - All packages from the original list (standard + custom)
# - R integration via rpy2
# - Data science tools: pandas, numpy, scipy, scikit-learn, tensorflow, etc.
# - Custom research packages: tretools, popcorn, yhaplo
# - Bioinformatics tools: scanpy, pysam, h5py, etc.
# - String similarity packages: polars-strsim, polars-distance, rapidfuzz
#
# Usage:
#   docker run -it tre-python-3.13-strsim:latest
#   python3 -c "import pandas, tretools, rpy2, polars_strsim; print('Ready for research!')"

# Set environment variables to allow uv to install packages system-wide
# This bypasses the "externally managed environment" restriction in containers
ENV UV_SYSTEM_PYTHON=1
ENV UV_BREAK_SYSTEM_PACKAGES=1
ENV UV_PYTHON_INSTALL_DIR=/opt/uv-python

# Update package lists and install R and Python development headers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        r-base \
        r-base-dev \
        python3-dev \
        build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install uv if not already present in base image
RUN pip install uv || echo "uv already installed"

# Install Python 3.13 via uv
RUN uv python install 3.13

# Set working directory
WORKDIR /app

# Copy Python project files
COPY pyproject.toml uv.lock ./

# Export dependencies from uv.lock to requirements.txt format
RUN uv export --format requirements.txt > requirements.txt

# Install Python dependencies system-wide using uv pip sync targeting Python 3.13
RUN uv pip sync --python 3.13 requirements.txt


# Create compatibility directory and Python 3.13 symlinks (before verify so python3.13 is in PATH)
RUN PYTHON313=$(find /opt/uv-python -name 'python3.13' -type f | head -1) && \
    echo "Found Python 3.13 at: $PYTHON313" && \
    test -n "$PYTHON313" && \
    test -x "$PYTHON313" && \
    mkdir -p /opt/view/bin/ && \
    ln -sf "$PYTHON313" /opt/view/bin/python3.13 && \
    ln -sf "$PYTHON313" /usr/local/bin/python3.13 && \
    ln -sf "$PYTHON313" /usr/local/bin/python3

# Verify installations
RUN python3.13 -c "import sys; print(f'Python: {sys.version}')" && \
    R --version | head -1 && \
    python3.13 -c "import tretools, popcorn, yhaplo, rpy2; print('✅ All custom packages imported successfully')" && \
    python3.13 -c "import polars_strsim, polars_distance, rapidfuzz; print('✅ String similarity packages imported successfully')"

# Install bcftools from apt
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bcftools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set proper entrypoint and command to bypass Spack shell integration
ENTRYPOINT ["/bin/bash"]
CMD ["-l"]
