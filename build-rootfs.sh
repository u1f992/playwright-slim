#!/bin/sh
set -eu

apt-get update
apt-get install --yes --no-install-recommends ca-certificates curl fakechroot fakeroot mmdebstrap

curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
bash nodesource_setup.sh
apt install --yes --no-install-recommends nodejs

rm -rf app
mkdir app
cd app
echo '{"private":true,"type":"module"}' >package.json
npm install --save playwright@1.55.0
npx playwright install --with-deps chromium --dry-run \
    | sed -n 's/.*apt-get install -y --no-install-recommends \(.*\)".*/\1/p' \
    >../deps.txt
npx playwright install --with-deps chromium

cd ..
mmdebstrap \
    --mode=fakeroot \
    --format=tar \
    --variant=custom \
    --dpkgopt='path-exclude=/usr/share/man/*' \
    --dpkgopt='path-exclude=/usr/share/locale/*/LC_MESSAGES/*.mo' \
    --dpkgopt='path-exclude=/usr/share/doc/*' \
    --dpkgopt='path-include=/usr/share/doc/*/copyright' \
    --setup-hook='mkdir -p "$1/usr/share/keyrings" "$1/etc/apt/sources.list.d" "$1/etc/apt/preferences.d"' \
    --setup-hook='cp /usr/share/keyrings/nodesource.gpg "$1/usr/share/keyrings/"' \
    --setup-hook='cp /etc/apt/sources.list.d/nodesource.list "$1/etc/apt/sources.list.d/"' \
    --setup-hook='cp /etc/apt/preferences.d/nodejs "$1/etc/apt/preferences.d/"' \
    --include="dash coreutils diffutils libc-bin perl-base debconf sed init-system-helpers util-linux nodejs $(cat deps.txt)" \
    --customize-hook='mkdir -p "$1/.cache"' \
    --customize-hook="copy-in /root/.cache/ms-playwright /.cache/" \
    --customize-hook="copy-in /workdir/app /" \
    bookworm rootfs.tar
