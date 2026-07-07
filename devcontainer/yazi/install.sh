#!/usr/bin/env bash
# Installs yazi (https://github.com/sxyazi/yazi), a terminal file manager.
# Installs both binaries it ships: `yazi` and its sidecar CLI `ya`.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${script_dir}/../lib.sh"

already_installed yazi && exit 0

detect_arch
ensure_prereqs

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "resolving latest yazi release for ${ARCH}..."
url="$(gh_asset_url sxyazi/yazi \
	"yazi-${ARCH}-unknown-linux-musl\.zip\$" \
	"yazi-${ARCH}-unknown-linux-gnu\.zip\$")"

echo "downloading ${url}..."
fetch_extract "$url" "$tmpdir"

install_bin "$(find "$tmpdir" -maxdepth 2 -type f -name yazi)" yazi
install_bin "$(find "$tmpdir" -maxdepth 2 -type f -name ya)" ya
