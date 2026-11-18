---
name: devcontainer-host
description: Use when running on the HOST, outside the SDK devcontainer (no /.dockerenv, cwd not under /workspaces), and about to run anything in the container (a build, a check script), when host git fails with "insufficient permission for adding an object to repository database" or another permission error under .git, when files in the checkout are owned by root, or when adb or a serial port fails in the container. Inside the container, use devcontainer instead; its "Why not root" section has the background.
---

# The SDK devcontainer, from the host

The container bind-mounts this checkout at `/workspaces/luckfox-pico-sdk`
and runs as `dev`, remapped to your uid/gid at start-up, so files it creates
belong to you. Background: the devcontainer skill, "Why not root".

## Running commands in the container

Find the container by the label VS Code puts on it, from the checkout root:

```bash
docker ps --filter "label=devcontainer.local_folder=$PWD" --format '{{.ID}}'
```

Zero or several results: stop and ask which one is the active workspace.

`docker exec` defaults to the image's user, root, not `remoteUser`. Always
pass the user:

```bash
docker exec -u dev -w /workspaces/luckfox-pico-sdk <id> ./build.sh
```

Run git on the host; it needs nothing from the container.

Do not change the container's state to make a command work. Rebuilding it
is the user's call (VS Code: Dev Containers: Rebuild Container).

## Root-owned files

A container from before the switch to `dev` (`id -u` is 0 inside) writes
root-owned files into the checkout, including `.git` objects; host git then
fails. Fix: rebuild the container, then hand the files back. List them, and
ask the user to run the `chown`, since it needs `sudo`:

```bash
find . -user root
sudo chown -R "$(id -un):$(id -gn)" .
```

Narrow the path when only `.git` is affected; a whole-tree `chown` also
hands back build output, which is slow.

Repos that were given `core.sharedRepository=group` as an earlier
workaround keep working; the setting is harmless and need not be undone.

## adb or serial fails in the container

`/dev` is the host's, so device nodes keep the host's group ids. `dev` is in
`plugdev` (46) and `dialout` (20). Compare with the host:

```bash
getent group plugdev dialout
ls -l /dev/ttyUSB* /dev/bus/usb/*/*
```

A mismatch, or a node owned by another group, needs a udev rule or group
change on the host, which is the user's to make.
