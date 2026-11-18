FROM ubuntu:22.04

LABEL maintainer="zhu30844" \
      description="Dev container for buildroot-based project on Luckfox board, place this file in the root of the SDK repo"

# ---------------------------------------------------------------------------
# Configurable from devcontainer.json -> build.args
# The defaults below only apply to a bare `docker build`; devcontainer.json
# overrides all three.
# ---------------------------------------------------------------------------
ARG LANG=C.UTF-8
ARG TZ=Etc/UTC
ARG GO_VERSION=1.27.3

# Build-time only, deliberately ARG and not ENV: keeps apt quiet during the
# build without leaking noninteractive into the running container's shell.
ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=${LANG} \
    LC_ALL=${LANG} \
    TZ=${TZ}

# Install development tools and dependencies for buildroot
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Build essentials
        gcc gcc-multilib g++ g++-multilib \
        make cmake bison flex fakeroot autoconf \
        gawk texinfo gperf \
        # Development tools
        git ssh vim \
        # Libraries and tools
        libssl-dev libncurses5-dev \
        device-tree-compiler \
        pkg-config bc \
        # Utilities
        module-assistant expect \
        unzip file cpio rsync wget patch \
        python-is-python3 \
        # System and network
        tzdata locales passwd openssl \
        openssh-server openssh-client \
        usbutils adb sudo \
        ca-certificates curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Locale. C.UTF-8 is built into glibc; any real locale has to be generated.
RUN if [ "${LANG}" != "C.UTF-8" ]; then locale-gen "${LANG}"; fi

# Timezone. Fail loudly on a typo instead of leaving a dangling symlink.
RUN [ -f "/usr/share/zoneinfo/${TZ}" ] || { echo "Unknown TZ: ${TZ}" >&2; exit 1; } && \
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
    echo "${TZ}" > /etc/timezone

# Install Go
RUN wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz" && \
    rm "go${GO_VERSION}.linux-amd64.tar.gz"

# Configure Go environment
ENV GOROOT=/usr/local/go
ENV PATH=$PATH:$GOROOT/bin

WORKDIR /workspace

# Non-root user for the devcontainer (devcontainer.json -> remoteUser), so
# files created in the bind-mounted checkout belong to the host user. Dev
# Containers remaps USER_UID/USER_GID to the host user's at start-up
# (updateRemoteUserUID). plugdev/dialout match the GIDs Ubuntu hosts give
# /dev nodes, for adb and serial. Passwordless sudo, so nothing ever stops
# a build to ask for a password. CI is unaffected: it runs with a numeric
# `docker run -u` and never uses this account.
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd -g "${USER_GID}" "${USERNAME}" && \
    useradd -m -s /bin/bash -u "${USER_UID}" -g "${USER_GID}" \
            -G plugdev,dialout "${USERNAME}" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" && \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

# Login greeting: print what .devcontainer/motd-gen.sh assembled at container
# start, once, in the first real terminal ([ -t 1 ] skips the shells VS Code
# extensions start). Every other shell pays two builtin tests and no fork.
RUN printf '%s\n' '' \
    '# devcontainer greeting, see .devcontainer/motd-gen.sh' \
    '[ -t 1 ] && [ -e "$HOME/.cache/devcontainer-motd/pending" ] && { cat "$HOME/.cache/devcontainer-motd/motd" 2>/dev/null; rm -f "$HOME/.cache/devcontainer-motd/pending"; }' \
    >> /etc/bash.bashrc
