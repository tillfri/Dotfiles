#!/usr/bin/env bash
# Installs starship (https://github.com/starship/starship) via the official
# installer, which already handles arch detection, sudo escalation and
# installs to /usr/local/bin by default.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${script_dir}/../lib.sh"

already_installed starship && exit 0

ensure_prereqs

curl -sS https://starship.rs/install.sh | sh -s -- --yes
