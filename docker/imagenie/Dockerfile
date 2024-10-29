# Start from Debian slim base
FROM debian:bullseye-slim

# Install system dependencies and Python
RUN apt-get update && \
    apt-get install -y \
    python3.9 \
    python3.9-venv \
    python3.9-distutils \
    python3-pip \
    wget \
    build-essential \
    squashfs-tools \
    libseccomp-dev \
    uuid-dev \
    pkg-config \
    curl \
    ca-certificates \
    gnupg \
    libssl-dev && \
    ln -s /usr/bin/python3.9 /usr/local/bin/python && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install requests google-cloud-storage

# Install Go, required for building Singularity
RUN wget -q https://go.dev/dl/go1.17.13.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.17.13.linux-amd64.tar.gz && \
    rm go1.17.13.linux-amd64.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && \
    echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile

# Install Singularity (Apptainer) for .sif conversion
RUN wget -q https://github.com/apptainer/singularity/releases/download/v3.8.7/singularity-3.8.7.tar.gz && \
    tar -xzf singularity-3.8.7.tar.gz && \
    cd singularity-3.8.7 && \
    export PATH=$PATH:/usr/local/go/bin && \
    ./mconfig && \
    make -C ./builddir && \
    make -C ./builddir install && \
    cd .. && rm -rf singularity-3.8.7 singularity-3.8.7.tar.gz

# Install Skopeo for image handling
RUN echo "deb [signed-by=/usr/share/keyrings/containers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list && \
    curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/Debian_11/Release.key | gpg --dearmor -o /usr/share/keyrings/containers-archive-keyring.gpg && \
    apt-get update && \
    apt-get install -y skopeo && \
    rm -rf /var/lib/apt/lists/*

# Install Trivy for scanning images
RUN wget -q https://github.com/aquasecurity/trivy/releases/download/v0.30.0/trivy_0.30.0_Linux-64bit.deb && \
    dpkg -i trivy_0.30.0_Linux-64bit.deb && \
    rm trivy_0.30.0_Linux-64bit.deb

# Install Google Cloud SDK
RUN curl -sSL https://sdk.cloud.google.com | bash && \
    echo "source /root/google-cloud-sdk/path.bash.inc" >> /root/.bashrc

# Set the working directory and copy application files
WORKDIR /workspace
COPY main.py ./

# Define the entry point
CMD ["python", "main.py"]

