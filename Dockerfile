FROM docker.io/amd64/debian:trixie-slim@sha256:98800cb0d57478d2e25fcb52951857e8ddf169d597c24601a0c28fe4fba4c892

RUN rm -f /etc/apt/sources.list.d/debian.sources \
    && printf '%s\n' \
        'deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20260823T000000Z trixie main' \
        > /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        bc \
        bison \
        build-essential \
        ca-certificates \
        flex \
        gawk \
        git \
        libelf-dev \
        libssl-dev \
        openssl \
        zstd \
    && rm -rf /var/lib/apt/lists/*
