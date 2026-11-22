FROM ubuntu:22.04

LABEL maintainer="zhu30844" \
      description="Dev container for buildroot-based project on Luckfox board, place this file in the root of the SDK repo"

# ---------------------------------------------------------------------------
# Configurable from devcontainer.json -> build.args
# The defaults below only apply to a bare `docker build`; devcontainer.json
# overrides them.
# ---------------------------------------------------------------------------
ARG LANG=C.UTF-8
ARG TZ=Etc/UTC
ARG GO_VERSION=1.27.3
ARG NODE_VERSION=26.13.1

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
        libsqlite3-dev libfreetype-dev libcjson-dev \
        device-tree-compiler \
        pkg-config bc \
        # Utilities
        module-assistant expect \
        zip unzip file cpio rsync wget patch \
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

# Install Node.js
RUN wget -q "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" && \
    rm -rf /usr/local/node && \
    mkdir /usr/local/node && \
    tar -C /usr/local/node --strip-components=1 -xzf "node-v${NODE_VERSION}-linux-x64.tar.gz" && \
    rm "node-v${NODE_VERSION}-linux-x64.tar.gz"

ENV PATH=$PATH:/usr/local/node/bin

WORKDIR /workspace

# Non-root user (remoteUser), with plugdev/dialout for adb and serial and
# passwordless sudo. Group root is for flashing: a board in Maskrom mode is
# a root:root 0664 node unless the host has a udev rule for it.
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd -g "${USER_GID}" "${USERNAME}" && \
    useradd -m -s /bin/bash -u "${USER_UID}" -g "${USER_GID}" \
            -G plugdev,dialout,root "${USERNAME}" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" && \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

# Print the greeting from motd-gen.sh once, in the first interactive terminal
RUN printf '%s\n' '' \
    '# devcontainer greeting, see .devcontainer/motd-gen.sh' \
    '[ -t 1 ] && [ -e "$HOME/.cache/devcontainer-motd/pending" ] && { cat "$HOME/.cache/devcontainer-motd/motd" 2>/dev/null; rm -f "$HOME/.cache/devcontainer-motd/pending"; }' \
    >> /etc/bash.bashrc
