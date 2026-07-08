#!/usr/bin/env bash
# Installs delta (https://github.com/dandavison/delta), a syntax-highlighting
# pager for git/diff output.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${script_dir}/../lib.sh"

already_installed delta && exit 0

detect_arch
ensure_prereqs

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "resolving latest delta release for ${ARCH}..."
# Note: musl builds are only published for x86_64; aarch64 only ships a gnu
# build, hence falling back to it.
url="$(gh_asset_url dandavison/delta \
	"delta-[0-9.]+-${ARCH}-unknown-linux-musl\.tar\.gz\$" \
	"delta-[0-9.]+-${ARCH}-unknown-linux-gnu\.tar\.gz\$")"

echo "downloading ${url}..."
fetch_extract "$url" "$tmpdir"

bin_path="$(find "$tmpdir" -maxdepth 2 -type f -name delta)"
install_bin "$bin_path" delta
