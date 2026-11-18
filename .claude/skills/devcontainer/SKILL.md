---
name: devcontainer
description: Use when running INSIDE the SDK devcontainer (/.dockerenv exists, cwd under /workspaces) and about to build, use adb or a serial port, run git, touch file ownership, or change .devcontainer/; also when something seems to need the host. Covers the `dev` user mapped to the host user, what works from inside, what to hand to the user for the host, and why the container no longer runs as root. On the host, outside the container, use devcontainer-host instead.
---

# Inside the SDK devcontainer

You run as `dev`: uid/gid remapped to the host user's at start-up
(`remoteUser` + `updateRemoteUserUID` in `devcontainer.json`), passwordless
sudo, in `plugdev` and `dialout`. Check with `id`.

`id -u` is 0: the container predates the switch to `dev`; ask the user to
rebuild it. Until then, run git as the host user
(`setpriv --reuid=1000 --regid=1000 --clear-groups env HOME=/tmp git -c safe.directory="$PWD" ...`)
and `chown 1000:1000` any file you write in the checkout.

The checkout is a bind mount of the host's at `/workspaces/luckfox-pico-sdk`.
The host path is not fixed; read it rather than assume one (fourth field):

```bash
grep ' /workspaces/luckfox-pico-sdk ' /proc/self/mountinfo
```

## Do it here

- Build: `./build.sh` (and `lunch`, `clean`). No build script calls sudo.
- Board: adb, serial (`/dev/ttyUSB*`), Maskrom flashing (`rkflash.sh`).
  The container is `--privileged` with the host's `/dev` mounted; hotplugged
  devices appear.
- Network to the board (ssh, scp, `adb connect`).
- git, including push: SSH goes through the agent VS Code forwards.

## Hand to the user

Write the exact command and let the user run it on the host; do not work
around the container to do it yourself.

- Rebuild or restart the container (VS Code: Dev Containers: Rebuild
  Container).
- `chown` of root-owned files, from the checkout root on the host:
  `sudo chown -R "$(id -un):$(id -gn)" .` (list them first:
  `find /workspaces/luckfox-pico-sdk -user root`).
- udev rules or group ids on the host.
- The board connecting back into the container (NFS, TFTP): needs
  `--network host` or a port mapping in `runArgs`, a `.devcontainer/` change
  plus a rebuild.

Never:

- mount `/var/run/docker.sock` into the container: it is root on the host;
- `git config --global safe.directory '*'`: it turns off git's ownership
  check for every repository.

## Board tools

Device nodes keep the host's group ids. `plugdev` (46) and `dialout` (20)
match Ubuntu hosts; on a permission error, ask the user for
`getent group plugdev dialout` on the host. `sudo adb` is the fallback. An
adb server from an old root session holds port 5037: `adb kill-server`.

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
