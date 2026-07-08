#!/usr/bin/env bash
# Shared helpers for devcontainer/*/install.sh scripts.
#
# These scripts download the latest upstream release of a CLI tool straight
# from its GitHub releases page and drop the binary into /usr/local/bin.
# There is no version pinning by design: run install-all.sh (or an
# individual install.sh) any time you want the current release.
#
# Source this file, don't execute it directly:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

# --- arch detection ----------------------------------------------------
#
# The container's architecture is what matters here, not the host machine's.
# On Apple Silicon, Docker Desktop runs containers natively as arm64 unless
# the image is only published for amd64 (common for nvidia/cuda tags), in
# which case Docker transparently emulates amd64 via QEMU. So always ask the
# running container via `uname -m` instead of assuming.
detect_arch() {
    ARCH="$(uname -m)"
    case "$ARCH" in
    x86_64 | aarch64) ;;
    arm64) ARCH="aarch64" ;; # normalize (seen on some non-Linux uname builds)
    *)
        echo "error: unsupported architecture '$ARCH'" >&2
        exit 1
        ;;
    esac
}

# --- privilege helper ----------------------------------------------------

as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "error: need root privileges to run: $*" >&2
        echo "       (not running as root and 'sudo' is not installed)" >&2
        exit 1
    fi
}

# --- prerequisites --------------------------------------------------------

ensure_prereqs() {
    local missing=()
    # file:  yazi shells out to `file(1)` for MIME-type detection; without
    #        it yazi warns it can't detect a file's type at all.
    # xclip: clipboard provider for nvim's `unnamedplus` and yazi's yank
    #        support (requires a forwarded DISPLAY to actually work; the
    #        binary just needs to be present to be picked up).
    for cmd in curl tar unzip nodejs npm file xclip; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    # curl doesn't pull in ca-certificates as a dependency on minimal/slim
    # base images, which then fails TLS verification against api.github.com
    # and *.githubusercontent.com. Make sure it's actually present, not just
    # that the package might be installed.
    [ -s /etc/ssl/certs/ca-certificates.crt ] || missing+=("ca-certificates")

    [ "${#missing[@]}" -eq 0 ] && return 0

    echo "installing missing prerequisites: ${missing[*]}"
    if ! command -v apt-get >/dev/null 2>&1; then
        echo "error: 'apt-get' not found, cannot auto-install: ${missing[*]}" >&2
        echo "       please install these manually and re-run" >&2
        exit 1
    fi
    as_root apt-get update -qq
    as_root apt-get install -y -qq --no-install-recommends "${missing[@]}"
    if [[ " ${missing[*]} " == *" ca-certificates "* ]]; then
        as_root update-ca-certificates >/dev/null
    fi
}

# --- GitHub releases -------------------------------------------------------

# gh_asset_url <owner/repo>[@<tag>] <regex> [<regex> ...]
#
# Fetches the JSON for the latest release once (or a specific tag, if
# <owner/repo>@<tag> is given — used when the current latest release isn't
# usable, e.g. built against a too-new glibc), then tries each regex in
# order against every asset's browser_download_url, returning the first
# match found. Multiple regexes let callers express a preference order,
# e.g. musl build first, falling back to the gnu build if musl isn't
# published for that architecture.
gh_asset_url() {
    local repo="$1"
    shift

    local tag=""
    if [[ "$repo" == *@* ]]; then
        tag="${repo#*@}"
        repo="${repo%%@*}"
    fi

    local auth_header=()
    [ -n "${GITHUB_TOKEN:-}" ] && auth_header=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

    local releases_path="releases/latest"
    [ -n "$tag" ] && releases_path="releases/tags/${tag}"

    local json
    json="$(curl -fsSL "${auth_header[@]}" -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${repo}/${releases_path}")" || {
        echo "error: failed to query GitHub API for ${repo}/${releases_path}" >&2
        echo "       (if this is a rate-limit, set GITHUB_TOKEN to raise the limit)" >&2
        exit 1
    }

    local urls
    urls="$(grep -oE '"browser_download_url": *"[^"]+"' <<<"$json" | grep -oE 'https://[^"]+')"

    local pattern url
    for pattern in "$@"; do
        url="$(grep -E "$pattern" <<<"$urls" | head -n1 || true)"
        if [ -n "$url" ]; then
            printf '%s\n' "$url"
            return 0
        fi
    done

    echo "error: no release asset of ${repo} matched any pattern: $*" >&2
    exit 1
}

# --- download / extract ---------------------------------------------------

# fetch_extract <url> <destdir>
#
# Downloads url into a temp file and extracts it into destdir (created if
# needed), handling .tar.gz/.tgz, .zip, and bare .gz (a single gzipped
# executable, no tar wrapper — used by e.g. tree-sitter's releases)
# transparently.
fetch_extract() {
    local url="$1" destdir="$2"
    mkdir -p "$destdir"

    local tmpfile
    tmpfile="$(mktemp)"
    curl -fsSL "$url" -o "$tmpfile"

    case "$url" in
    *.tar.gz | *.tgz)
        tar -xzf "$tmpfile" -C "$destdir"
        ;;
    *.zip)
        unzip -q -o "$tmpfile" -d "$destdir"
        ;;
    *.gz)
        gunzip -c "$tmpfile" >"${destdir}/$(basename "${url%.gz}")"
        ;;
    *)
        rm -f "$tmpfile"
        echo "error: don't know how to extract '$url'" >&2
        exit 1
        ;;
    esac
    rm -f "$tmpfile"
}

# --- install ---------------------------------------------------------------

# install_bin <src_path> <dest_name>
#
# Installs a single executable into /usr/local/bin under dest_name.
install_bin() {
    local src="$1" name="$2"
    as_root install -m 755 "$src" "/usr/local/bin/${name}"
    echo "installed $(command -v "$name" 2>/dev/null || echo "/usr/local/bin/${name}")"
}

# already_installed <cmd>
#
# Returns success (skip re-install) if cmd is already on PATH and FORCE=1
# was not set. Individual install.sh scripts opt into this check.
already_installed() {
    local cmd="$1"
    if [ "${FORCE:-0}" != "1" ] && command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd already installed at $(command -v "$cmd"), skipping (set FORCE=1 to reinstall)"
        return 0
    fi
    return 1
}
