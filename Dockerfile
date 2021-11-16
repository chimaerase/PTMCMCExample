FROM library/python:3.9-slim-bullseye
LABEL maintainer="Mark Forrer<mark.forrer@lbl.gov>"
ENV PYTHONUNBUFFERED=1 LANG=C.UTF-8
COPY Pipfile* /tmp/
WORKDIR /tmp

RUN set -ex \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
    # install Git so we can clone newer acor from GitHub (as suggested by PTMCMCSampler)
    git \
    # install direct mpi4py dependencies to use PTMCMCSampler's MPI support
    gcc \
    libopenmpi-dev \
    # install acor dependencies. acor is an optional dependency of PTMCMCSampler.
    python3-dev \
    g++ \
 # clean up install artifacts to keep image small
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 # upgrade Python install tools
 && pip install --upgrade pip \
 && pip install --upgrade pipenv \
 # install Python production and dev packages to enable, e.g. pytest
 && pipenv install --dev --system --deploy --verbose \
 && rm /tmp/Pipfile* \
 # add a user and group so we don't have problems executing mpirun as root
 && addgroup --gid 1000 --system mpiuser \
 && adduser --uid 1000 mpiuser --gid 1000

# copy example code into the image
COPY gaussian_example.py /code/

RUN chown -R mpiuser:mpiuser /code/

WORKDIR /code/
USER mpiuser
ENTRYPOINT ["/bin/bash"]
