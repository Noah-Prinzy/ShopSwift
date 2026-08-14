# syntax=docker/dockerfile:1

# Keep the same Flyway CLI used by local development available in the runtime
# image so a hosted container can apply the versioned SQL migrations before
# Vapor starts.
FROM redgate/flyway:latest AS flyway

# ShopSwift is compiled in Linux so Vapor's Unix-oriented dependencies never
# use the native Windows Swift toolchain.
FROM swift:6.3.3-jammy AS builder

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        libpq-dev \
        libssl-dev \
        pkg-config \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Package.resolved is intentionally not required here because it is not tracked
# in this repository. SwiftPM resolves dependencies from Package.swift in clean
# cloud builds, matching what a fresh deployment environment actually has.
COPY Package.swift ./
RUN --mount=type=cache,id=shopswift-swiftpm,target=/build/.build \
    swift package resolve

COPY Sources ./Sources
COPY Tests ./Tests
COPY Public ./Public
COPY Resources ./Resources

RUN --mount=type=cache,id=shopswift-swiftpm,target=/build/.build \
    swift build -c debug --product Run --jobs 4 \
    && mkdir -p /output \
    && cp "$(swift build -c debug --show-bin-path)/Run" /output/Run

# The official slim image supplies the Swift Linux runtime without retaining
# compilers, package checkouts, or other build-only files.
FROM swift:6.3.3-jammy-slim AS runtime

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        libssl3 \
        tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --create-home vapor

WORKDIR /app

COPY --from=builder /output/Run ./Run
COPY --from=builder /build/Public ./Public
COPY --from=builder /build/Resources ./Resources
COPY scripts/start.sh ./scripts/start.sh

# Flyway and its bundled Java runtime are copied from the official image. This
# lets the same container safely run V1/V2 (and future migrations) before the
# server accepts traffic in hosted environments.
COPY --from=flyway /flyway /flyway
COPY --from=flyway /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="/flyway:/opt/java/openjdk/bin:${PATH}"

RUN chmod +x ./scripts/start.sh \
    && chown -R vapor:vapor /app
USER vapor

EXPOSE 8080

ENTRYPOINT ["./scripts/start.sh"]
