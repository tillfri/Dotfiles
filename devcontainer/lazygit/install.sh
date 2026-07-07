#!/usr/bin/env bash
# Installs lazygit (https://github.com/jesseduffield/lazygit).
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${script_dir}/../lib.sh"

already_installed lazygit && exit 0

detect_arch
ensure_prereqs

case "$ARCH" in
x86_64) lazygit_arch=x86_64 ;;
aarch64) lazygit_arch=arm64 ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "resolving latest lazygit release for ${lazygit_arch}..."
url="$(gh_asset_url jesseduffield/lazygit \
	"lazygit_[0-9.]+_[Ll]inux_${lazygit_arch}\.tar\.gz\$")"

echo "downloading ${url}..."
fetch_extract "$url" "$tmpdir"

install_bin "${tmpdir}/lazygit" lazygit
