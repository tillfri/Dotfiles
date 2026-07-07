#!/usr/bin/env bash
# Runs every devcontainer/*/install.sh in this repo, installing all devtools
# in one go. Intended usage: clone this dotfiles repo into any container
# (FROM ubuntu, cuda, python, ...) and run this script.
#
#   git clone <dotfiles-repo> ~/dotfiles
#   ~/dotfiles/devcontainer/install-all.sh
#
# Env vars:
#   FORCE=1          reinstall even if a tool is already on PATH
#   GITHUB_TOKEN=... raise the unauthenticated GitHub API rate limit
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for install_script in "${script_dir}"/*/install.sh; do
	tool="$(basename "$(dirname "$install_script")")"
	echo "==> installing ${tool}"
	"$install_script"
	echo
done

echo "all devtools installed."
