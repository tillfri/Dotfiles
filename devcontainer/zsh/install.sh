#!/usr/bin/env bash
# Installs zsh and points $HOME/.zshrc at this repo's container-friendly
# config (../../zsh/.zshrc_container), which only relies on tools installed
# by the other devcontainer/*/install.sh scripts.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${script_dir}/../lib.sh"

repo_root="$(cd "${script_dir}/../.." && pwd)"
zshrc_container="${repo_root}/zsh/.zshrc_container"

if ! already_installed zsh; then
	ensure_prereqs
	if ! command -v apt-get >/dev/null 2>&1; then
		echo "error: 'apt-get' not found, cannot auto-install zsh" >&2
		echo "       please install it manually and re-run" >&2
		exit 1
	fi
	echo "installing zsh..."
	as_root apt-get update -qq
	as_root apt-get install -y -qq --no-install-recommends zsh
fi

if [ ! -f "$zshrc_container" ]; then
	echo "error: expected to find ${zshrc_container}" >&2
	echo "       (is the dotfiles repo checked out fully?)" >&2
	exit 1
fi

ln -sf "$zshrc_container" "$HOME/.zshrc"
echo "linked ~/.zshrc -> ${zshrc_container}"

zsh_path="$(command -v zsh)"
if command -v chsh >/dev/null 2>&1; then
	current_shell="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7 || true)"
	if [ "$current_shell" != "$zsh_path" ]; then
		if as_root chsh -s "$zsh_path" "$(id -un)" 2>/dev/null; then
			echo "set zsh as default shell for $(id -un)"
		else
			echo "note: could not chsh automatically; run 'chsh -s ${zsh_path}' or just start it with 'exec zsh'"
		fi
	fi
else
	echo "note: 'chsh' not available; start zsh manually with 'exec zsh'"
fi
