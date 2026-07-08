# devcontainer

Install scripts that pull the current release binary of a few CLI tools
straight from GitHub and drop them into `/usr/local/bin` inside a container.

The idea: these dotfiles already contain the configuration for these tools
(see `../config/.config/`). Clone this repo into *any* container — no matter
what it's `FROM` (`ubuntu`, `nvidia/cuda`, `python`, ...) — run one script,
and you get the same tooling + config everywhere.

No versions are pinned and nothing goes through a package manager (`apt`,
etc.) for the tools themselves — each `install.sh` just fetches the latest
GitHub release for the container's actual architecture. Run it again later
to update.

## Layout

```
devcontainer/
├── lib.sh            # shared helpers, sourced by every install.sh below
├── install-all.sh     # runs every */install.sh
├── delta/install.sh
├── fd/install.sh
├── fzf/install.sh
├── lazygit/install.sh
├── nvim/install.sh
├── rg/install.sh       # ripgrep
├── starship/install.sh
├── tree-sitter/install.sh
├── yazi/install.sh
└── zsh/install.sh
```

Each subdirectory is named after the binary/command it installs (`rg` for
ripgrep, etc.), matching the tool names used in `../config/.config/`.

`zsh` is a bit different from the rest: instead of pulling a GitHub release,
it `apt-get install`s zsh and symlinks `../zsh/.zshrc_container` (a trimmed
copy of the host `.zshrc` containing only what's guaranteed to work with the
other 9 tools here — see that file's header for exactly what was left out
and why) to `$HOME/.zshrc`, then sets zsh as the default shell.

## Quick start

Inside the container:

```sh
git clone https://github.com/tillfri/Dotfiles ~/dotfiles
~/dotfiles/devcontainer/install-all.sh
```

That's it — `fd`, `rg`, `fzf`, `lazygit`, `starship`, `yazi`/`ya`,
`tree-sitter`, `delta`, `nvim`, and `zsh` (set as your default shell, with
`~/.zshrc` linked automatically) are now installed.

To install just one tool:

```sh
~/dotfiles/devcontainer/lazygit/install.sh
```

### Getting the dotfiles configuration too

Installing the binaries is only half the point — symlink the matching
configs from this repo into place so nvim/starship/lazygit/yazi actually
look the way you expect:

```sh
mkdir -p ~/.config
for d in ~/dotfiles/config/.config/*/; do
	name="$(basename "$d")"
	ln -sfn "$d" "$HOME/.config/$name"
done
```

(Only symlink the ones you care about if you don't want all of
`config/.config/*` — e.g. just `nvim`, `starship`, `lazygit`, `yazi`.)

The shell setup (`~/.zshrc`) is handled for you by `zsh/install.sh` (see
above) — no manual step needed there.

## Using it in a Dockerfile

```dockerfile
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && \
    git clone --depth 1 https://github.com/tillfri/Dotfiles /opt/dotfiles && \
    /opt/dotfiles/devcontainer/install-all.sh && \
    ln -sfn /opt/dotfiles/config/.config/nvim /root/.config/nvim && \
    ln -sfn /opt/dotfiles/config/.config/starship /root/.config/starship && \
    ln -sfn /opt/dotfiles/config/.config/lazygit /root/.config/lazygit && \
    ln -sfn /opt/dotfiles/config/.config/yazi /root/.config/yazi

SHELL ["/bin/zsh", "-c"]
```

## Using it in `devcontainer.json`

```jsonc
{
	"image": "python:3.12",
	"postCreateCommand": "git clone <your-dotfiles-repo-url> ~/dotfiles && ~/dotfiles/devcontainer/install-all.sh"
}
```

## Notes

- **Architecture**: each script detects the architecture *of the running
  container* via `uname -m` (`x86_64`/`aarch64`) and downloads the matching
  asset. This matters because the container's architecture doesn't always
  match the host machine's: on Apple Silicon, Docker Desktop runs multi-arch
  images (`ubuntu`, `python`, ...) natively as `arm64`, but images that are
  only published for `amd64` (e.g. most `nvidia/cuda` tags) get silently run
  under QEMU emulation as `amd64`. Detecting at runtime handles both cases
  and every other host/image combination without any manual configuration.
- **Re-running / updates**: each `install.sh` skips reinstalling if the
  binary is already on `PATH`. Force a fresh install with `FORCE=1`:
  ```sh
  FORCE=1 ~/dotfiles/devcontainer/install-all.sh
  ```
- **Prerequisites**: scripts assume a Debian/Ubuntu base (true for `ubuntu`,
  `python`, `nvidia/cuda` images) and will `apt-get install` `curl`, `tar`,
  `unzip`, `ca-certificates`, `nodejs`, `npm` (needed by several nvim
  plugins/LSPs), `file` (needed by yazi for MIME-type detection), and
  `xclip` (clipboard provider for nvim's `unnamedplus` and yazi's yank
  support — only works if `DISPLAY` is forwarded into the container)
  themselves if missing. They escalate via `sudo` automatically when not
  already running as root.
- **GitHub API rate limits**: resolving the latest release for most tools
  hits the unauthenticated GitHub API (60 requests/hour per IP). If you hit
  that limit (e.g. rebuilding containers repeatedly in CI), set
  `GITHUB_TOKEN` in the environment before running the scripts to raise it.
- **libc variant**: where a tool ships both, the static `musl` build is
  preferred (works unmodified on any distro), falling back to `gnu` when
  `musl` isn't published for that architecture (this varies release to
  release for some tools, e.g. ripgrep).
- `starship` is the one exception — it uses the project's own official
  installer (`https://starship.rs/install.sh`), which already does its own
  arch detection and installs to `/usr/local/bin`.
- `nvim` isn't a standalone static binary; its release is a full tree
  (`bin/`, `lib/`, `share/`), so it's extracted to `/opt/nvim` with a symlink
  from `/usr/local/bin/nvim`.
- `zsh` doesn't come from a GitHub release at all — it's `apt-get install`ed
  and paired with `../zsh/.zshrc_container`, a config trimmed down to only
  what's guaranteed to work with the other 9 tools here (no eza, bat,
  zoxide, direnv, opencode, Hyprland, kitty, etc.). It also sets zsh as the
  default shell via `chsh` where possible.

## Adding a new tool

1. `mkdir devcontainer/<name>` and create `<name>/install.sh` (copy an
   existing one as a starting point, e.g. `fd/install.sh` for a single
   tar.gz-packaged static binary).
2. Source `../lib.sh` and use `gh_asset_url`, `fetch_extract`, and
   `install_bin` to resolve, download, and install the right asset for
   `$ARCH` (call `detect_arch` first).
3. Make it executable: `chmod +x devcontainer/<name>/install.sh`.
4. It'll automatically be picked up by `install-all.sh`.
