#!/usr/bin/env bash
# Installs fd (https://github.com/sharkdp/fd), a fast alternative to `find`.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${script_dir}/../lib.sh"

already_installed fd && exit 0

detect_arch
ensure_prereqs

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "resolving latest fd release for ${ARCH}..."
url="$(gh_asset_url sharkdp/fd \
	"fd-v[0-9.]+-${ARCH}-unknown-linux-musl\.tar\.gz\$" \
	"fd-v[0-9.]+-${ARCH}-unknown-linux-gnu\.tar\.gz\$")"

echo "downloading ${url}..."
fetch_extract "$url" "$tmpdir"

bin_path="$(find "$tmpdir" -maxdepth 2 -type f -name fd)"
install_bin "$bin_path" fd
