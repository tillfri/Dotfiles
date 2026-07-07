#!/usr/bin/env bash
# Installs ripgrep (https://github.com/BurntSushi/ripgrep) as `rg`.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${script_dir}/../lib.sh"

already_installed rg && exit 0

detect_arch
ensure_prereqs

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "resolving latest ripgrep release for ${ARCH}..."
# Note: ripgrep's published assets are inconsistent release to release
# (currently only x86_64-musl and aarch64-gnu exist), hence trying both
# libc variants for both architectures.
url="$(gh_asset_url BurntSushi/ripgrep \
	"ripgrep-[0-9.]+-${ARCH}-unknown-linux-musl\.tar\.gz\$" \
	"ripgrep-[0-9.]+-${ARCH}-unknown-linux-gnu\.tar\.gz\$")"

echo "downloading ${url}..."
fetch_extract "$url" "$tmpdir"

bin_path="$(find "$tmpdir" -maxdepth 2 -type f -name rg)"
install_bin "$bin_path" rg
