#!/usr/bin/env bash
# Claude Code status line: RGB gradient, context size, cost, code velocity,
# right-aligned model + rate limits

input=$(cat)

# ── Colors ──
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Truecolor helper ──
rgb() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }

# ── Parse JSON fields ──
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
effort=$(echo "$input" | jq -r '
    (.model.effort // .effort // empty) as $e
    | if ($e | type) == "object" then ($e.level // empty) else $e end
')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_del=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
five_hr=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ── Effort: not in the status line JSON (yet), fall back to settings ──
if [ -z "$effort" ]; then
    for f in "$cwd/.claude/settings.local.json" "$cwd/.claude/settings.json" \
        "$HOME/.claude/settings.local.json" "$HOME/.claude/settings.json"; do
        [ -r "$f" ] || continue
        effort=$(jq -r '.effortLevel // empty' "$f" 2>/dev/null)
        [ -n "$effort" ] && break
    done
fi

# ── Git info ──
branch=""
repo=""
if [ -n "$cwd" ]; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
    repo=$(basename "$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
fi

# ── Last 2 path components of pwd ──
path_short=""
if [ -n "$cwd" ]; then
    path_short="$(basename "$(dirname "$cwd")")/$(basename "$cwd")"
fi

# ── Context bar: RGB gradient, full blocks only ──
BAR_WIDTH=8

if [ -n "$used" ]; then
    used_int=$(printf '%.0f' "$used")

    # Round to nearest block
    filled=$(((used_int * BAR_WIDTH + 50) / 100))

    bar=""
    for ((i = 0; i < BAR_WIDTH; i++)); do
        pos=$((i * 100 / (BAR_WIDTH - 1)))

        if [ "$pos" -le 50 ]; then
            r=$((0 + 220 * pos / 50))
            g=200
            b=$((80 - 80 * pos / 50))
        else
            adj=$((pos - 50))
            r=220
            g=$((200 - 160 * adj / 50))
            b=$((0 + 20 * adj / 50))
        fi

        if [ "$i" -lt "$filled" ]; then
            bar="${bar}$(rgb $r $g $b)█"
        else
            bar="${bar}\033[38;2;60;60;60m░"
        fi
    done
    bar="${bar}${RESET}"

    if [ "$used_int" -ge 90 ]; then
        ctx_color="$RED"
    elif [ "$used_int" -ge 70 ]; then
        ctx_color="$YELLOW"
    else ctx_color="$GREEN"; fi
else
    bar="\033[38;2;60;60;60m░░░░░░░░${RESET}"
    ctx_color="$GREEN"
fi

# ── Raw context size, e.g. 25k ──
if [ -n "$tokens" ] && [ "$tokens" -gt 0 ] 2>/dev/null; then
    if [ "$tokens" -ge 1000 ]; then
        ctx_size="$(((tokens + 500) / 1000))k"
    else
        ctx_size="$tokens"
    fi
else
    ctx_size="--"
fi

ctx_part="${bar} ${ctx_color}${ctx_size}${RESET}"
# plain twin for width math (bar is multi-byte, count it as BAR_WIDTH cells)
ctx_plain="$(printf '%*s' "$BAR_WIDTH" '') ${ctx_size}"

# ── Cost ──
cost_str=$(printf '$%.2f' "$cost")
cost_part="${YELLOW}${cost_str}${RESET}"

# ── Code velocity ──
velocity="${GREEN}+${lines_add}${RESET} ${RED}-${lines_del}${RESET}"
velocity_plain="+${lines_add} -${lines_del}"

# ── Left side ──
left=""
left_plain=""
if [ -n "$path_short" ]; then
    left="${DIM}${path_short}${RESET}"
    left_plain="$path_short"
fi
if [ -n "$repo" ]; then
    left="${left:+$left }${BOLD}${YELLOW}${repo}${RESET}"
    left_plain="${left_plain:+$left_plain }$repo"
fi
if [ -n "$branch" ]; then
    left="${left:+$left }${BOLD}${CYAN}(${branch})${RESET}"
    left_plain="${left_plain:+$left_plain }(${branch})"
fi
left="${left:+$left ${DIM}|${RESET} }${ctx_part}"
left_plain="${left_plain:+$left_plain | }${ctx_plain}"
left="${left} ${DIM}|${RESET} ${cost_part}"
left_plain="${left_plain} | ${cost_str}"
left="${left} ${DIM}|${RESET} ${velocity}"
left_plain="${left_plain} | ${velocity_plain}"

# ── Right side: model + effort, rate limits ──
pct_color() {
    if [ "$1" -ge 90 ]; then
        printf '%b' "$RED"
    elif [ "$1" -ge 70 ]; then
        printf '%b' "$YELLOW"
    else printf '%b' "$GREEN"; fi
}

model_label="${model}${effort:+ $effort}"
right="${MAGENTA}${model_label}${RESET}"
right_plain="$model_label"

if [ -n "$five_hr" ]; then
    v=$(printf '%.0f' "$five_hr")
    right="${right} ${DIM}5h:${RESET} $(pct_color "$v")${v}%${RESET}"
    right_plain="${right_plain} 5h: ${v}%"
fi
if [ -n "$seven_day" ]; then
    v=$(printf '%.0f' "$seven_day")
    right="${right} ${DIM}|${RESET} ${DIM}7d:${RESET} $(pct_color "$v")${v}%${RESET}"
    right_plain="${right_plain} | 7d: ${v}%"
fi

# ── Compose: left, padding, right ──
width=${COLUMNS:-$(tput cols 2>/dev/null || echo 100)}
right_margin=4
pad=$((width - right_margin - ${#left_plain} - ${#right_plain}))
[ "$pad" -lt 2 ] && pad=2

printf '%b%*s%b' "$left" "$pad" '' "$right"
