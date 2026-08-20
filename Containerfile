# syntax=docker/dockerfile:1
FROM docker.io/alpine:latest AS base

FROM base AS builder

ARG BRANCH

RUN set -ex && \
    apk add --no-cache --upgrade \
        git \
        python3 \
        build-base \
        cmake \
        curl-dev \
        gettext-dev \
        openssl-dev \
        linux-headers \
        samurai

WORKDIR /usr/src
RUN git clone https://github.com/transmission/transmission transmission

WORKDIR /usr/src/transmission
RUN git checkout ${BRANCH} && git submodule update --init --recursive

RUN cmake \
        -S . \
        -B obj \
        -G Ninja \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_CLI=OFF \
        -D ENABLE_DAEMON=ON \
        -D ENABLE_GTK=OFF \
        -D ENABLE_MAC=OFF \
        -D ENABLE_QT=OFF \
        -D ENABLE_TESTS=OFF \
        -D ENABLE_UTILS=OFF \
        -D ENABLE_UTP=ON \
        -D ENABLE_WERROR=OFF \
        -D ENABLE_DEPRECATED=OFF \
        -D ENABLE_NLS=ON \
        -D INSTALL_WEB=ON \
        -D REBUILD_WEB=OFF \
        -D INSTALL_DOC=OFF \
        -D INSTALL_LIB=OFF \
        -D RUN_CLANG_TIDY=OFF \
        -D WITH_INOTIFY=ON \
        -D WITH_CRYPTO="openssl" \
        -D WITH_SYSTEMD=OFF && \
    cmake --build obj --config Release; \
    cmake --build obj --config Release --target install/strip

FROM base AS runtime

RUN set -ex && \
    apk update && \
    apk add --no-cache --upgrade libcurl libintl libgcc libstdc++ curl jq tzdata

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/share /usr/local/share

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

EXPOSE 9091/tcp 51413/tcp 51413/udp
VOLUME /config /watch /download

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
