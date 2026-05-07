FROM mercury/softpack-build:0.21.1.2

# Python 3.13 + String Similarity Research Environment (Mercury/Softpack-compatible)
# Matches the pattern of tre-python: UV_SYSTEM_PYTHON=1, packages installed into
# python3.13's own site-packages (no venv), symlink at /opt/view/bin/python3.13.
#
# Usage:
#   docker build -t tre-python-3.13-strsim:latest .
#   singularity build singularity.sif docker-daemon://tre-python-3.13-strsim:latest

ENV UV_SYSTEM_PYTHON=1
ENV UV_BREAK_SYSTEM_PACKAGES=1
ENV UV_PYTHON_INSTALL_DIR=/opt/uv-python

# System dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        curl \
        ca-certificates \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libncursesw5-dev \
        tk-dev \
        liblzma-dev \
        gfortran \
        libblas-dev \
        liblapack-dev \
        libopenblas-dev \
        bcftools \
        r-base \
        r-base-dev \
        python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install uv || echo "uv already installed"

# Install Python 3.13 via uv
RUN uv python install 3.13

WORKDIR /app

# Copy project definition and resolve lock for Python 3.13
COPY pyproject.toml ./
RUN uv lock --python 3.13

# Export and install packages system-wide into Python 3.13 site-packages (no venv)
RUN uv export --format requirements-txt --no-hashes > requirements.txt
RUN uv pip install --python 3.13 -r requirements.txt

# Symlink python3.13 binary into standard locations
RUN mkdir -p /opt/view/bin && \
    ln -sf "$(uv python find 3.13)" /opt/view/bin/python3.13 && \
    ln -sf "$(uv python find 3.13)" /usr/local/bin/python3.13 && \
    ln -sf "$(uv python find 3.13)" /usr/local/bin/python3

# Verify
RUN python3 -c "import sys; print(f'Python: {sys.version}')" && \
    R --version | head -1 && \
    python3 -c "import tretools, popcorn, yhaplo, rpy2; print('Custom packages OK')" && \
    python3 -c "import pandas, numpy, scanpy, tensorflow; print('Core packages OK')" && \
    python3 -c "import polars_strsim, polars_distance, rapidfuzz; print('String similarity packages OK')"

# Register Jupyter kernel
RUN python3 -m ipykernel install --sys-prefix --name python3.13-strsim --display-name "Python 3.13 (TRE strsim)"

ENTRYPOINT ["/bin/bash"]
CMD ["-l"]
