```
$ ./build.sh
$ docker run --mount type=bind,source="$(pwd)",target=/app/mnt -it --rm playwright-slim mnt/test.js
```

with [container2wasm](https://github.com/container2wasm/container2wasm):

```
$ c2w --build-arg VM_MEMORY_SIZE_MB=1024 playwright-slim:latest playwright-slim.wasm
$ wasmtime --dir .::/app/mnt playwright-slim.wasm mnt/test.js
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

特定のバイナリを含むパッケージを検索（例：`sh`）

```
$ docker run -it --rm debian:bookworm bash -c "apt update && apt install --yes --no-install-recommends apt-file && apt-file update && apt-file search -x 'bin/sh$'"
```

---

`essential`→`custom`

ふつう依存関係はaptによって解決されるけど、フックスクリプトに使われるバイナリがessentialに含まれている場合、それは依存関係にリストアップされていない。実行してトライアンドエラーで確かめる必要がある……

```
dpkg: warning: 'sh' not found in PATH or not executable
dpkg: warning: 'rm' not found in PATH or not executable
dpkg: warning: 'diff' not found in PATH or not executable
dpkg: warning: 'ldconfig' not found in PATH or not executable

dash: /bin/sh
coreutils: /bin/rm
diffutils: /usr/bin/diff
libc-bin: /sbin/ldconfig
```

```
Setting up debconf (1.5.82) ...
/var/lib/dpkg/info/debconf.postinst: 17: exec: /usr/share/debconf/frontend: not found
dpkg: error processing package debconf (--install):
 installed debconf package post-installation script subprocess returned error exit status 127

Setting up python3.11 (3.11.2-6+deb12u6) ...
/var/lib/dpkg/info/python3.11.postinst: 7: sed: not found
dpkg: error processing package python3.11 (--install):
 installed python3.11 package post-installation script subprocess returned error exit status 127

Setting up python3 (3.11.2-1+b1) ...
/var/lib/dpkg/info/python3.postinst: 18: sed: not found
dpkg: error processing package python3 (--install):
 installed python3 package post-installation script subprocess returned error exit status 127

Setting up ca-certificates (20230311+deb12u1) ...
/var/lib/dpkg/info/ca-certificates.postinst: 17: exec: /usr/share/debconf/frontend: not found
dpkg: error processing package ca-certificates (--install):
 installed ca-certificates package post-installation script subprocess returned error exit status 127

Setting up fontconfig-config (2.14.1-4) ...
/var/lib/dpkg/info/fontconfig-config.postinst: 17: exec: /usr/share/debconf/frontend: not found
dpkg: error processing package fontconfig-config (--install):
 installed fontconfig-config package post-installation script subprocess returned error exit status 127

Setting up x11-common (1:7.7+23) ...
/var/lib/dpkg/info/x11-common.postinst: 17: exec: /usr/share/debconf/frontend: not found
dpkg: error processing package x11-common (--install):
 installed x11-common package post-installation script subprocess returned error exit status 127

debconf: /usr/share/debconf/frontend
sed: /bin/sed
```

なぜPythonが……

debconfのインストールにdebconfが要求されている？

`/usr/share/debconf/frontend`を見てみると、perl-baseが必要かも

```
#!/usr/bin/perl -w
# This file was preprocessed, do not edit!


use strict;
use Debconf::Db;
use Debconf::Template;
use Debconf::AutoSelect qw(:all);
use Debconf::Log qw(:all);

Debconf::Db->load;

debug developer => "frontend started";
...

perl-base: /usr/bin/perl
```

```
Setting up x11-common (1:7.7+23) ...
Use of uninitialized value in concatenation (.) or string at /usr/share/perl5/Debconf/Config.pm line 22.
/var/lib/dpkg/info/x11-common.postinst: 13: update-rc.d: not found
dpkg: error processing package x11-common (--install):
 installed x11-common package post-installation script subprocess returned error exit status 127

init-system-helpers: /usr/sbin/update-rc.d
```

```
Setting up usrmerge (37~deb12u1) ...
Can't exec "mountpoint": No such file or directory at /usr/lib/usrmerge/convert-usrmerge line 429.
Failed to execute mountpoint -q /lib/modules/: No such file or directory
E: usrmerge failed.
dpkg: error processing package usrmerge (--install):
 installed usrmerge package post-installation script subprocess returned error exit status 1

util-linux: /bin/mountpoint
```

これでファイルシステム構築は通ったが、ダウンロード済みブラウザのパスが変わった。

```
> const browser = await chromium.launch();
Uncaught:
browserType.launch: Executable doesn't exist at /.cache/ms-playwright/chromium_headless_shell-1187/chrome-linux/headless_shell
```