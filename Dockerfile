# Runs the AIContextBuilder MCP server in a container.
#
# This repository holds no source code, so nothing is built here: the image
# installs the published .NET tool from nuget.org - the same package a local
# `dotnet tool install -g aicb-roslyn-mcp` gives you.
#
#   docker build -t aicb .
#
#   # 1. Restore the solution INSIDE the container - once, and again after
#   #    every package change (see "Why the restore runs in here" below).
#   docker run --rm --user "$(id -u):$(id -g)" \
#     -v "$PWD:/src" -v aicb-nuget:/home/aicb/.nuget/packages \
#     --entrypoint dotnet aicb restore /src/App.sln
#
#   # 2. Serve MCP. This is the command line an MCP client starts.
#   docker run --rm -i --user "$(id -u):$(id -g)" \
#     -v "$PWD:/src" -v aicb-nuget:/home/aicb/.nuget/packages aicb
#
# The server speaks MCP over stdio, so `-i` is required and there is no port to
# publish. Mount the solution you want analyzed and pass its path inside the
# container (/src/App.sln) as the `sessionId` of any tool call - every tool
# accepts the absolute .sln / .slnx / .slnf path directly (self-init), so there
# is no separate analyze step.
#
# WHY `--user "$(id -u):$(id -g)"`. The image runs as a non-root user (see USER
# below), and analysis WRITES into the mounted solution: a restore writes
# obj/project.assets.json, and the MSBuild design-time build that opens a
# solution can write generated files under obj/. A bind mount keeps the host's
# file owners, so the container must write as someone the host lets write there.
# Running as the host user's own uid guarantees that without loosening any
# permission on the host. Without `--user` the container runs as uid 1654, which
# can write to the mount only if you made it writable for that uid. A read-only
# mount (`:ro`) has not been measured.
#
# WHY THE RESTORE RUNS IN HERE. AICB does not restore; the solution must be
# restored before it is analyzed. A restore records the absolute path of the
# NuGet package folder in obj/project.assets.json, and the design-time build
# resolves package references through that path. A restore on the host records a
# host path that does not exist in the container, so the packages - and, for any
# target other than net10.0, the framework's reference assemblies, which also
# come from NuGet - would be missing. A restore in the container records
# /home/aicb/.nuget/packages, and the named volume `aicb-nuget` keeps that folder
# for the server run. Side effect: it rewrites obj/ of the mounted solution with
# container paths; the next restore on the host (every `dotnet build` runs one)
# writes the host's back. Use the same `--user` for every run against one volume.

# The SDK image rather than the runtime image is deliberate: analyzing a
# solution needs MSBuild. The server starts and answers tools/list without it,
# so a runtime image would produce a container that looks healthy and fails at
# the first real question.
#
# .NET 10 since 0.5.500.1: the tool targets .NET 10 from that version on and does
# not start on the .NET 8 image this file used before.
FROM mcr.microsoft.com/dotnet/sdk:10.0

# Unpinned on purpose: this image is meant to track the current release. Add
# `--version 0.5.500.1` or later when you need a reproducible build (versions
# before 0.5.465.11 were published as AIContextBuilder).
#
# --tool-path instead of -g: a global tool lands in /root/.dotnet/tools, which a
# non-root user can neither read nor execute. /opt/aicb is a system location
# outside every home directory. `chmod a+rX` makes it readable and executable
# for every uid, whatever modes the package extraction left behind, and clearing
# the NuGet cache keeps a second copy of the package out of the image.
RUN dotnet tool install aicb-roslyn-mcp --tool-path /opt/aicb \
    && chmod -R a+rX /opt/aicb \
    && dotnet nuget locals all --clear

ENV PATH="${PATH}:/opt/aicb"

# One HOME for every uid, writable by every uid. The .NET SDK, NuGet and MSBuild
# write below HOME (first-run files, the package folder, the design-time build
# cache, the settings directory), so an unwritable HOME breaks the first restore
# or analysis. The base image's `app` user has /home/app, but a uid passed with
# `--user` has no passwd entry, and Docker then sets HOME to `/`, which only root
# can write. So HOME is set explicitly, to a directory with the mode of /tmp
# (1777: anyone may create, the sticky bit stops one uid deleting another's
# files). One path for every uid also gives the package volume one documented
# mount target.
#
# The package folder and /data exist in the image, with the same mode, for a
# second reason: a NEW named volume mounted on a directory that exists in the
# image is initialized from that directory, ownership and mode included. A mount
# target that does not exist in the image is created owned by root, and the
# non-root user could not write into its own volume.
RUN mkdir -p /home/aicb/.nuget/packages /data \
    && chmod 1777 /home/aicb /home/aicb/.nuget /home/aicb/.nuget/packages /data

ENV HOME=/home/aicb

WORKDIR /src

# Non-root by default. The base image (runtime-deps, which the sdk image builds
# on) creates the user `app` and exports its uid as APP_UID, but it does not
# switch to it - without this line the server would run as root while it runs
# the MSBuild logic and source generators of a mounted solution. The numeric
# form is the one Microsoft recommends for its .NET images: Kubernetes can
# enforce `runAsNonRoot` only against a numeric uid, and the variable avoids
# repeating the number here. `docker run --user` overrides it, which is the
# documented way to match the owner of the mounted solution (see the header).
USER $APP_UID

# --db-path names a container-local config database, and the path deliberately
# need not exist. Measured against 0.5.464.36: a missing file is NOT created and
# does NOT abort the start - the server prints
#   warning: --db-path not found (...); starting without a profile
# and serves the default tool pool. That is the behavior this image wants, and
# naming the path explicitly is what keeps it deterministic: without the flag
# the server resolves the desktop app's database location instead, which does
# not exist in a container and is a path nobody has measured here.
#
# Mount a volume at /data to keep MCP profiles and insights between runs; the
# desktop app creates that database, the server alone does not. The server
# records every tool call in that database (fail-open), so a mounted file should
# be writable for the uid the container runs as.
ENTRYPOINT ["aicb", "mcp", "--db-path", "/data/aicb.acb"]
