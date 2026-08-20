# Base image is plain Debian (base:debian), not Ubuntu — see devcontainer.json's opening
# comment. Everything else is installed by features in devcontainer.json, except
# libnss3-tools/chromium/chromium-sandbox: those three are baked in here as a RUN layer
# instead of living in postCreateCommand (where they used to be, alongside the dev-cert
# NSS trust step that still lives there) specifically so Docker caches the install.
# postCreateCommand re-runs on every "Rebuild Container", re-downloading and
# re-installing chromium's dependency chain every single time and giving a transient
# mirror/network blip a fresh chance to fail the whole devcontainer create. A RUN layer
# here only re-executes when this file changes.
# --no-install-recommends: without it, chromium drags in ~150 transitive packages via
# Recommends -- a full desktop stack (avahi-daemon, cups printing, X11 utils, GTK,
# systemd-cryptsetup, a terminal emulator, notification-daemon) that a headless
# Playwright-driven Chromium never touches; its actual runtime Depends, including fonts,
# are unaffected. chromium-sandbox is named explicitly because it's also only a
# Recommends, not a Depends -- but it's the setuid sandbox helper Chromium needs for
# safe unprivileged rendering, costs nothing extra (only depends on libc6), and the
# Playwright MCP server (.mcp.json) launches this same /usr/bin/chromium headless.
FROM mcr.microsoft.com/devcontainers/base:debian

RUN apt-get -o Acquire::Retries=3 update -qq \
    && apt-get -o Acquire::Retries=3 install -y -qq --no-install-recommends libnss3-tools chromium chromium-sandbox \
    && rm -rf /var/lib/apt/lists/*

# Cloud/database CLI tooling for local dev DB access and eventual cloud testing.
# postgresql-client is packaged directly in Debian's own repos (confirmed on this base
# image's Debian 13/trixie) -- no extra repo needed. azure-cli deliberately does NOT live
# here even though Debian also carries it directly -- see the postCreateCommand's
# "azure-cli" step in devcontainer.json: it's pip-installed against the python feature's
# 3.14 instead, so it rides the same interpreter as CSnakes and updates with a plain
# `pip install --upgrade` instead of an apt/Dockerfile change.
# mssql-tools18 (sqlcmd/bcp) only ships from Microsoft's own apt repo; packages-microsoft-prod.deb
# both adds that repo and installs its signing key, so no manual gpg/keyring dance is needed.
# ACCEPT_EULA=Y is required non-interactively, per Microsoft's own Docker install guidance --
# without it, apt-get blocks on a EULA prompt with no controlling tty and the build hangs.
# unixodbc-dev is mssql-tools18's own declared dependency, not incidental.
RUN curl -sSL -O https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get -o Acquire::Retries=3 update -qq \
    && ACCEPT_EULA=Y apt-get -o Acquire::Retries=3 install -y -qq --no-install-recommends postgresql-client mssql-tools18 unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*
ENV PATH="${PATH}:/opt/mssql-tools18/bin"

# AWS CLI and Pulumi have no Debian-native or Microsoft-repo apt package -- both ship only as
# their own curl-based installers, so they land in their own layer separate from the apt-based
# tools above instead of pretending to be apt installs.
# AWS CLI: official installer only distributes as a per-arch zip (x86_64/aarch64, matching
# `uname -m` directly since this build always targets the host running `docker build`, never
# cross-compiled) -- no apt/deb package is published upstream.
# Pulumi: --install-root /usr/local lands `pulumi` and its bundled per-language plugins
# straight in /usr/local/bin, already on PATH for every user, instead of the installer's
# default of a per-user ~/.pulumi/bin that `vscode` wouldn't inherit from this root-run layer.
RUN ARCH="$(uname -m)" \
    && curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o awscliv2.zip \
    && unzip -q awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws \
    && curl -fsSL https://get.pulumi.com | sh -s -- --install-root /usr/local --no-edit-path
