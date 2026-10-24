---
name: devcontainer
description: Use when running any command in the SDK devcontainer from the host (a build, a check script, git), when git on the host fails with "insufficient permission for adding an object to repository database" or any other permission error under .git, when files in the checkout turn out to be owned by root, or when changing .devcontainer/. The container runs everything as root on a bind mount of the host checkout; this covers what that does to the host's files and git repos, and how to run commands so it does not.
---

# The SDK devcontainer runs as root

`.devcontainer/` builds an Ubuntu image with the cross toolchain and Go, and
runs **everything as root**: there is no `remoteUser`. That is deliberate.
Buildroot here is a single-user build and the board tooling (adb, `/dev`,
`--privileged`) expects root.

The host checkout is bind-mounted, not copied:

| Host | Container |
|---|---|
| `/home/range/Code/luckfox-pico-sdk` | `/workspaces/luckfox-pico-sdk` |

So every file the container creates in the checkout is owned by root on the
host. For build output that is harmless. For a git repository it is not.

## What goes wrong

The VS Code window attached to the container runs its git integration as
root. On every file save it writes into the repository: loose objects (blobs
of the saved files) and `config` (`vscode-merge-base`). For MotionSense these
land in the submodule's git dir, `.git/modules/project/app/motionsense/`.

Git on the host, running as `range`, then cannot write into the root-owned
`objects/xx/` directories:

```
error: insufficient permission for adding an object to repository database .../objects
fatal: updating files failed
```

This was traced on 2026-10-24: the root-owned objects were blobs of exactly
the files being saved at the time, and `config` gained `vscode-merge-base`.
It recurs as long as that VS Code window is open, whatever the agent does.

## Running commands in the container

Find the container by the label VS Code puts on it, from the SDK root:

```bash
docker ps --filter "label=devcontainer.local_folder=$PWD" --format '{{.ID}}'
```

Zero or several results: stop and ask which one is the active workspace.

- **Builds** (`./build.sh`, buildroot, the cross toolchain) run as root, the
  way the container expects:
  `docker exec -w /workspaces/luckfox-pico-sdk <id> ./build.sh`
- **Everything else** (git, check scripts, formatters, anything that may
  write into the checkout) runs as the host user:
  `docker exec -u 1000:1000 -w /workspaces/luckfox-pico-sdk/project/app/motionsense <id> python3 -I -B .claude/skills/path-references/scripts/check.py`
- Prefer the host shell for git altogether; it needs nothing from the
  container.

Do not change the container's state to make a command work. In particular,
never add `git config --global safe.directory '*'` as root: it switches off
git's ownership check for every repository in the container.

## One-time fix: shared repositories

`core.sharedRepository=group` makes git create directories group-writable
and setgid, so a directory root creates still belongs to the `range` group
and the host can write into it. Tested on 2026-10-24 against root writes
from the container (a new object directory, `index`, a `config` rewrite):
host `git add`, `commit` and `config` all succeeded afterwards.

It needs the repos owned by `range` first (see Recovery), then, from the SDK
root on the host:

```bash
for d in .git $(find .git/modules -type d -name objects -printf '%h\n'); do
    git --git-dir="$d" config core.sharedRepository group
    find "$d" -type d -exec chmod g+ws {} +
    find "$d" -type f ! -path '*/objects/*' -exec chmod g+w {} +
done
```

Loose objects stay read-only, as git intends; what matters is that their
directories are group-writable. This keeps the container all-root and needs
no change to `.devcontainer/`. The alternative, a `remoteUser` with uid 1000,
fixes it at the source but means `sudo` for the build and the board tools.

## Recovery

List what root owns, then hand it back. `sudo` is the user's to run; ask
them to type it with the `!` prefix:

```bash
find /home/range/Code/luckfox-pico-sdk -user root
! sudo chown -R range:range /home/range/Code/luckfox-pico-sdk/.git
```

Narrow the path to what `find` reported; a whole-tree `chown` also hands
back build output, which is fine but slow.
