FROM python:3.11-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies needed to build some Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git wget curl ca-certificates \
    libfreetype6-dev libpng-dev libglib2.0-0 libeigen3-dev libxml2-dev libxslt1-dev \
    libffi-dev ffmpeg pkg-config swig libhdf5-dev && rm -rf /var/lib/apt/lists/*

# Create a virtual environment and ensure it's first on PATH
RUN python -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH

# Upgrade packaging tools
RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel

WORKDIR /app

# Clone the mber-open repository directly from GitHub
RUN git clone https://github.com/manifoldbio/mber-open.git /app/mber-open
WORKDIR /app/mber-open

# Install OpenMM from PyPI (version 8.1.1 is available, close to 8.0.0 specified in environment.yml)
RUN python -m pip install --no-cache-dir openmm>=8.0.0

# Install pdbfixer from GitHub (depends on OpenMM which we just installed)
RUN python -m pip install --no-cache-dir git+https://github.com/openmm/pdbfixer.git

# Install ANARCI from GitHub (bioconda-only package)
# ANARCI requires HMMER and MUSCLE for building HMM databases
RUN apt-get update && apt-get install -y --no-install-recommends hmmer muscle && rm -rf /var/lib/apt/lists/*

# Install ANARCI following Spack recipe approach
RUN git clone https://github.com/oxpig/ANARCI.git /tmp/anarci && \
    cd /tmp/anarci && \
    # Patch setup.py to disable custom install command that causes issues
    sed -i 's/from distutils.core import setup/from setuptools import setup/' setup.py && \
    sed -i 's/cmdclass\s*=\s*{[^}]*}/cmdclass={}/' setup.py && \
    # Install via pip without build isolation
    python -m pip install --no-cache-dir --no-build-isolation --no-deps . && \
    # Build HMM databases from IMGT data
    cd build_pipeline && bash RUN_pipeline.sh && cd .. && \
    # Copy generated data files to installed package location
    SITE_PACKAGES=$(python -c "import site; print(site.getsitepackages()[0])") && \
    mkdir -p ${SITE_PACKAGES}/anarci/dat && \
    cp build_pipeline/curated_alignments/germlines.py ${SITE_PACKAGES}/anarci/ && \
    cp -r build_pipeline/HMMs ${SITE_PACKAGES}/anarci/dat/ && \
    # Clean up
    cd / && rm -rf /tmp/anarci

# Install all other requirements normally from PyPI
RUN python -m pip install --no-cache-dir -r requirements.txt || true

# Install the local packages in editable mode (allow pip to resolve deps from the ones we've installed).
RUN python -m pip install --no-cache-dir -e .
RUN python -m pip install --no-cache-dir -e protocols

# Download optional assets without failing the build
RUN bash download_af_weights.sh || true

# Default to the venv python
CMD ["/opt/venv/bin/python3"]
