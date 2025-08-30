```
$ ./build.sh
$ docker run -it --rm playwright-slim
```

## メモ

`--setup-hook`の変更内容は`nodesource_setup.sh`を読んで決めた。

`--dpkgopt`の除外設定は、[Ubuntu Base 24.04.3 (Noble Numbat)](https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/)の`/etc/dpkg/dpkg.cfg.d/excludes`に書いてある（[参考](https://gihyo.jp/admin/serial/01/ubuntu-recipe/0594)）。

```
# Drop all man pages
path-exclude=/usr/share/man/*

# Drop all translations
path-exclude=/usr/share/locale/*/LC_MESSAGES/*.mo

# Drop all documentation ...
path-exclude=/usr/share/doc/*

# ... except copyright files ...
path-include=/usr/share/doc/*/copyright

# ... and Debian changelogs for native & non-native packages
path-include=/usr/share/doc/*/changelog.*
```

distrolessイメージのダンプ

```
$ cid=$(docker create gcr.io/distroless/nodejs22-debian12)
$ mkdir distroless-nodejs22-debian12
$ docker export "$cid" | tar -x -C distroless-nodejs22-debian12
$ docker rm "$cid"
```
