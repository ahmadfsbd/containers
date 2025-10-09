FROM mercury/softpack-build:0.21.1.2

# Python Research Environment Container
# This container includes:
# - All 178 packages from the original list (standard + custom)
# - R integration via rpy2  
# - Data science tools: pandas, numpy, scipy, scikit-learn, tensorflow, etc.
# - Custom research packages: tretools, popcorn, yhaplo
# - Bioinformatics tools: scanpy, pysam, h5py, etc.
#
# Usage:
#   docker run -it python-research-env:latest
#   python3 -c "import pandas, tretools, rpy2; print('Ready for research!')"

# Set environment variables to allow uv to install packages system-wide
# This bypasses the "externally managed environment" restriction in containers
ENV UV_SYSTEM_PYTHON=1
ENV UV_BREAK_SYSTEM_PACKAGES=1

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

# Set working directory
WORKDIR /app

# Copy Python project files
COPY pyproject.toml uv.lock ./

# Export dependencies from uv.lock to requirements.txt format
RUN uv export --format requirements.txt > requirements.txt

# Install Python dependencies system-wide using uv pip sync
RUN uv pip sync requirements.txt


# Verify installations
RUN python3 -c "import sys; print(f'Python: {sys.version}')" && \
    R --version | head -1 && \
    python3 -c "import tretools, popcorn, yhaplo, rpy2; print('✅ All custom packages imported successfully')"

# Create compatibility directory and Python symlink
RUN mkdir -p /opt/view/bin/ && \
    ln -sf $(which python3) /opt/view/bin/python3.10

# Install bcftools from apt
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bcftools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set proper entrypoint and command to bypass Spack shell integration
ENTRYPOINT ["/bin/bash"]
CMD ["-l"] 