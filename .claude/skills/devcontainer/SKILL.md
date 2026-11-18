---
name: devcontainer
description: Use when running any command in the SDK devcontainer from the host (a build, a check script, git), when git on the host fails with "insufficient permission for adding an object to repository database" or any other permission error under .git, when files in the checkout turn out to be owned by root, or when changing .devcontainer/. The container runs as a non-root user mapped to the host user on a bind mount of the host checkout; this covers how that works, the root-owned leftovers from the earlier all-root setup, and how to run commands so the checkout stays owned by the host.
---

# The SDK devcontainer runs as the host user

`.devcontainer/` builds an Ubuntu image with the cross toolchain and Go. The
image has a user `dev` (uid/gid 1000, passwordless sudo, in `plugdev` and
`dialout`), and `devcontainer.json` sets `"remoteUser": "dev"` with
`updateRemoteUserUID`, so Dev Containers remaps `dev` to the host user's
uid/gid when the container starts.

The host checkout is bind-mounted, not copied:

| Host | Container |
|---|---|
| `/home/range/Code/luckfox-pico-sdk` | `/workspaces/luckfox-pico-sdk` |

Files the container creates in the checkout therefore belong to the host
user, including what VS Code's git integration writes into `.git` on every
save.

## Why not root

Until 2026-11 the container ran everything as root. VS Code's git
integration then wrote root-owned loose objects and `config`
(`vscode-merge-base`) into the repos, for MotionSense into
`.git/modules/project/app/motionsense/`, and host git failed with:

```
error: insufficient permission for adding an object to repository database .../objects
fatal: updating files failed
```

Root was thought necessary for buildroot and the board tools. It is not:

- No build script under `project/` or `sysdrv/` calls `sudo`; the `mount`
  calls in `project/build.sh` are inside heredocs written into the rootfs
  for the board, not run on the build host.
- CI (`.github/workflows/release.yml`) has always run `./build.sh` in this
  image with `docker run -u "$(id -u):$(id -g)"`, as a non-root uid with no
  passwd entry, and passes.
- If a step ever does need root, `sudo` is passwordless and cannot stall a
  build on a prompt.

CI does not use `dev`: its numeric `-u` overrides the image user. Keep it
that way; do not make the workflow depend on the account.

## Running commands in the container

Find the container by the label VS Code puts on it, from the SDK root:

```bash
docker ps --filter "label=devcontainer.local_folder=$PWD" --format '{{.ID}}'
```

Zero or several results: stop and ask which one is the active workspace.

`docker exec` defaults to the image's user, which is root, not `remoteUser`.
Always pass the user:

```bash
docker exec -u dev -w /workspaces/luckfox-pico-sdk <id> ./build.sh
```

Prefer the host shell for git altogether; it needs nothing from the
container.

Do not change the container's state to make a command work. In particular,
never add `git config --global safe.directory '*'`: it switches off git's
ownership check for every repository in the container.

## Board tools

`/dev` is bind-mounted from the host, so device nodes keep the host's
group ids. `dev` is in `plugdev` (46) and `dialout` (20), which match
Ubuntu hosts; check the host with `getent group plugdev dialout` if adb or
a serial port reports a permission error. `sudo adb` is the fallback. An
adb server left from a root session holds port 5037: `adb kill-server`.

## Recovery: root-owned leftovers

The all-root setup left root-owned files: `.git` objects, build output under
`output/` and buildroot. `dev` cannot write into them. List them, then hand
them back. `sudo` is the user's to run; ask them to type it with the `!`
prefix:

```bash
find /home/range/Code/luckfox-pico-sdk -user root
! sudo chown -R range:range /home/range/Code/luckfox-pico-sdk
```

Narrow the path to what `find` reported when only `.git` is affected; a
whole-tree `chown` also hands back build output, which is what you want
after the switch but is slow.

Repos that were given `core.sharedRepository=group` as the earlier
workaround keep working; the setting is harmless and need not be undone.
