#!/usr/bin/env bash
# Installs Neovim (https://github.com/neovim/neovim) nightly-stable prebuilt
# binary. Unlike the other tools here, nvim's release is a full tree
# (bin/lib/share) rather than a standalone static binary, so it's extracted
# to /opt/nvim and symlinked into /usr/local/bin.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${script_dir}/../lib.sh"

already_installed nvim && exit 0

detect_arch
ensure_prereqs

case "$ARCH" in
x86_64) nvim_arch=x86_64 ;;
aarch64) nvim_arch=arm64 ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "resolving latest nvim release for ${nvim_arch}..."
url="$(gh_asset_url neovim/neovim \
	"nvim-linux-${nvim_arch}\.tar\.gz\$")"

echo "downloading ${url}..."
fetch_extract "$url" "$tmpdir"

extracted_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d)"

as_root rm -rf /opt/nvim
as_root mv "$extracted_dir" /opt/nvim
as_root ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

echo "installed $(command -v nvim)"
