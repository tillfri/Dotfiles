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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "resolving latest tree-sitter release for ${ts_arch}..."
url="$(gh_asset_url tree-sitter/tree-sitter \
	"tree-sitter-cli-linux-${ts_arch}\.zip\$")"

echo "downloading ${url}..."
fetch_extract "$url" "$tmpdir"

install_bin "$(find "$tmpdir" -maxdepth 2 -type f -name tree-sitter)" tree-sitter
