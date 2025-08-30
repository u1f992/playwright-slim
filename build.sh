#!/bin/sh
set -eu

IMAGE_NAME="${IMAGE_NAME:-playwright-slim}"
TAG_NAME="${TAG_NAME:-latest}"

docker run --mount type=bind,source="$(pwd)",target=/workdir --rm --tty --workdir /workdir debian:bookworm ./build-rootfs.sh
cat rootfs.tar | docker import --change "WORKDIR /app" --change 'ENTRYPOINT ["/usr/bin/node"]' - "${IMAGE_NAME}:${TAG_NAME}"
