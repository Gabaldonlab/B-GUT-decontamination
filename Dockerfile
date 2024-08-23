# Base image for bioinformatics tools
FROM ubuntu:22.04

LABEL maintainer="Olfat Khannous"
LABEL description="Docker container for B-gut decontamination"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies for apt-fast installation.
RUN apt-get update
RUN apt-get install -y \
        curl \
        wget \
        software-properties-common
RUN apt-get clean

# Add apt-fast repository to install apt-fast,
# which will make the package installation faster and concurrent.
RUN /bin/bash -c "$(curl -sL https://git.io/vokNn)"
RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt-get update

# Install system dependencies and tools
RUN DEBCONF_NOWARNINGS="yes" \
    TZ="Europe/Madrid" \
    DEBIAN_FRONTEND=noninteractive \
    apt-fast install -y --no-install-recommends \
    build-essential \
    gcc \
    git \
    wget \
    curl \
    gnupg \
    unzip \
    gfortran \
    zlib1g-dev \
    libssl-dev \
    libxml2-dev \
    python3.9 \
    python3-pip \
    python3.9-dev \
    python3.9-venv \
    lsb-release \
    libblas-dev \
    liblapack-dev \
    ca-certificates \
    libcurl4-openssl-dev \
    r-base \
    r-cran-diptest \
    r-bioc-phyloseq \
    r-bioc-biomformat \
    r-cran-biocmanager

# Set the default Python version for 3.9 as first in priority.
RUN update-alternatives --install /usr/bin/python3 python /usr/bin/python3.9 1
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install SeqKit
WORKDIR /usr/local/bin
RUN wget https://github.com/shenwei356/seqkit/releases/download/v2.3.0/seqkit_linux_amd64.tar.gz
RUN tar xvf seqkit_linux_amd64.tar.gz
RUN chmod +x seqkit

# Install Kraken2
WORKDIR /usr/local/bin
RUN wget https://github.com/DerrickWood/kraken2/archive/v2.1.2.tar.gz
RUN tar -xvzf v2.1.2.tar.gz

WORKDIR /usr/local/bin/kraken2-2.1.2
RUN ./install_kraken2.sh /usr/local/bin/

# Install via pip3 for Python 3.9:
# - pulp==2.7.0 (This specific version is required by Snakemake for Python3.9. If not Snakemake has a bug for version 2.8.0)
# - Snakemake
# - Kraken-biom
# - tiara
RUN python3.9 -m pip install \
    pulp==2.7.0 \
    snakemake \
    kraken-biom \
    tiara

# Install Bioconductor and required R packages
RUN Rscript -e "install.packages('phylotools', repos='http://cran.us.r-project.org')"
RUN Rscript -e "if (!require('phylotools')) { quit(status=1) } else { cat('phylotools is installed correctly\n') }"

WORKDIR /root

# Test installations
RUN tiara -h
RUN kraken2 -h
RUN seqkit -h
RUN kraken-biom -h
RUN snakemake -h

# Default command
CMD ["/bin/bash"]
