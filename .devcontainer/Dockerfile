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
