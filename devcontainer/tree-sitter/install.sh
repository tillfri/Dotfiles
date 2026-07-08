#!/usr/bin/env bash
# Installs the tree-sitter CLI (https://github.com/tree-sitter/tree-sitter)
# as `tree-sitter`. Required by nvim's nvim-treesitter plugin to compile
# parsers.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${script_dir}/../lib.sh"

already_installed tree-sitter && exit 0

detect_arch
ensure_prereqs

case "$ARCH" in
x86_64) ts_arch=x64 ;;
aarch64) ts_arch=arm64 ;;
esac

# tree-sitter's Linux release binaries are dynamically linked against glibc
# (no musl build is published), and as of v0.26.1 they require GLIBC_2.39
# (Ubuntu 24.04+), which fails to even load ("version `GLIBC_2.39' not
# found") on older bases like Ubuntu 22.04/Debian 12. Fall back to the last
# release known to work with an older glibc (v0.25.10, requires <= 2.34)
# when the container's glibc is too old for the latest release.
repo="tree-sitter/tree-sitter"
min_glibc="2.39"
fallback_tag="v0.25.10"

glibc_ver="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
if [ -z "${glibc_ver:-}" ]; then
	echo "warning: couldn't detect glibc version, assuming latest tree-sitter release works" >&2
elif [ "$(printf '%s\n%s\n' "$glibc_ver" "$min_glibc" | sort -V | head -n1)" != "$min_glibc" ]; then
	echo "detected glibc ${glibc_ver} (< ${min_glibc}); using tree-sitter ${fallback_tag} instead of latest"
	repo="${repo}@${fallback_tag}"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "resolving tree-sitter release for ${ts_arch}..."
url="$(gh_asset_url "$repo" \
	"tree-sitter-linux-${ts_arch}\.gz\$")"

echo "downloading ${url}..."
fetch_extract "$url" "$tmpdir"

install_bin "$(find "$tmpdir" -maxdepth 1 -type f -name "tree-sitter-linux-${ts_arch}")" tree-sitter
