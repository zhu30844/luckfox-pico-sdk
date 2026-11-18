#!/usr/bin/env bash
# Devcontainer login greeting, printed by /etc/bash.bashrc.
#   motd-gen.sh          cache OS, toolchain, Go          (postCreateCommand)
#   motd-gen.sh --start  add board, git, disk; mark pending (postStartCommand)

set -u

SDK=${LF_SDK:-$(cd "$(dirname "$0")/.." && pwd)}
DIR="$HOME/.cache/devcontainer-motd"
mkdir -p "$DIR"

B=$'\e[1m' D=$'\e[2m' C=$'\e[36m' R=$'\e[0m'
row() { printf ' %s*%s %-11s %s\n' "$C" "$R" "$1:" "$2"; }

# postCreate: cache fixed facts
if [ "${1:-}" != --start ]; then
    . /etc/os-release
    gcc=$(ls "${LF_TOOLCHAIN:-/nonexistent}"/bin/*-linux-*-gcc 2>/dev/null | head -1)
    if [ -n "$gcc" ]; then
        tc="$(basename "${gcc%-gcc}") $("$gcc" -dumpversion)"
    else
        tc="not found (LF_TOOLCHAIN=${LF_TOOLCHAIN:-unset})"
    fi
    go=$(go env GOVERSION 2>/dev/null || echo "not found")
    {
        printf '%s\n' "$PRETTY_NAME"
        row Toolchain "$tc"
        row Go "$go"
    } > "$DIR/static"
    exit 0
fi

# postStart: read cache, collect changing facts
static=()
mapfile -t static < "$DIR/static" 2>/dev/null
os=${static[0]:-"(run motd-gen.sh to fill in)"}

board=$(readlink "$SDK/.BoardConfig.mk" 2>/dev/null)
board=${board:+$(basename "$(dirname "$board")") ($(basename "$board"))}

git_line=$(git -C "$SDK" -c safe.directory="$SDK" \
    log -1 --format='%h %s' 2>/dev/null)
branch=$(git -C "$SDK" -c safe.directory="$SDK" \
    symbolic-ref --short -q HEAD 2>/dev/null || echo detached)

disk=$(df -h --output=avail "$SDK" 2>/dev/null | tail -1 | tr -d ' ')

# Assemble the greeting
{
    printf '%sWelcome to LuckfoxPico-MotionSense devcontainer%s %s(%s)%s\n\n' \
        "$B" "$R" "$D" "$os" "$R"
    row User "$(id -un) (uid $(id -u))   Host: $(hostname)"
    row Board "${board:-not selected (./build.sh lunch)}"
    [ ${#static[@]} -gt 1 ] && printf '%s\n' "${static[@]:1}"
    row Git "$branch @ ${git_line:-unknown}"
    row Disk "$disk free on $SDK"
    printf '\n %sBuild:%s ./build.sh   %sClean:%s ./build.sh clean   %sBoard:%s ./build.sh lunch\n\n' \
        "$B" "$R" "$B" "$R" "$B" "$R"
} > "$DIR/motd"

# Mark it for the first terminal
: > "$DIR/pending"
