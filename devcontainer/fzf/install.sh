#!/usr/bin/env bash
# Installs fzf (https://github.com/junegunn/fzf), a fuzzy finder.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${script_dir}/../lib.sh"

already_installed fzf && exit 0

detect_arch
ensure_prereqs

case "$ARCH" in
x86_64) fzf_arch=amd64 ;;
aarch64) fzf_arch=arm64 ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "resolving latest fzf release for ${fzf_arch}..."
url="$(gh_asset_url junegunn/fzf \
	"fzf-[0-9.]+-linux_${fzf_arch}\.tar\.gz\$")"

echo "downloading ${url}..."
fetch_extract "$url" "$tmpdir"

install_bin "${tmpdir}/fzf" fzf
