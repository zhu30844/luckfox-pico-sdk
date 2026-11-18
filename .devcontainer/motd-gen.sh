#!/usr/bin/env bash
# Login greeting for the devcontainer, generated off the terminal's hot path.
#
#   motd-gen.sh          postCreateCommand: the slow, fixed facts (OS,
#                        toolchain, Go), cached once per container build.
#   motd-gen.sh --start  postStartCommand: the facts that change (board,
#                        git, disk), then assembles the greeting and marks
#                        it pending. No adb: starting its server takes
#                        seconds, and a device count from start-up is stale
#                        by the time anyone plugs a board in.
#
# /etc/bash.bashrc prints the greeting in the first interactive terminal
# after each start and clears the mark, so later terminals cost two
# builtin tests and no fork. Nothing here runs in CI.

set -u

SDK=${LF_SDK:-$(cd "$(dirname "$0")/.." && pwd)}
DIR="$HOME/.cache/devcontainer-motd"
mkdir -p "$DIR"

B=$'\e[1m' D=$'\e[2m' C=$'\e[36m' R=$'\e[0m'
row() { printf ' %s*%s %-11s %s\n' "$C" "$R" "$1:" "$2"; }

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

: > "$DIR/pending"
