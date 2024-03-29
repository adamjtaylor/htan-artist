# Following:
# https://pythonspeed.com/articles/conda-docker-image-size/

# The build-stage image:
FROM continuumio/miniconda3 AS build

# File Author / Maintainer
MAINTAINER Adam Taylor <adam.taylor@sagebase.org>

# Install the package as normal:
COPY environment.yml .
RUN conda env create -f environment.yml

# Install conda-pack:
RUN conda install -c conda-forge conda-pack

# Use conda-pack to create a standalone enviornment
# in /venv:
RUN conda-pack -n artist -o /tmp/env.tar && \
  mkdir /venv && cd /venv && tar xf /tmp/env.tar && \
  rm /tmp/env.tar

# We've put venv in same path it'll be in final image,
# so now fix up paths:
RUN /venv/bin/conda-unpack


# The runtime-stage image; we can use Debian as the
# base image since the Conda env also includes Python
# for us.
FROM debian:bullseye AS runtime

# Copy /venv from the previous stage:
COPY --from=build /venv /venv

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install --yes --no-install-recommends \
    wget \
    locales \
    vim-tiny \
    git \
    cmake \
    build-essential \
    libopenslide-dev \
    python3-dev \
    python3-pip \
    libblosc1

RUN source /venv/bin/activate && \
    git clone https://github.com/adamjtaylor/miniature.git && \
    git clone https://github.com/jmuhlich/auto-minerva.git && \
    git clone https://github.com/labsyspharm/minerva-author.git && \
    git clone https://github.com/ncihtan/image-header-validation && \
    wget https://gist.githubusercontent.com/adamjtaylor/964e206bf1e6f302f6e512082e953193/raw/0acdea0736a027a260a0bb598f619552ff106758/index.html && \
    pip install git+https://github.com/labsyspharm/minerva-lib-python@master#egg=minerva-lib && \
    pip install openslide-python && \
    pip install opencv-python-headless \
    pip install synapseclient

ENV VIRTUAL_ENV=/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
