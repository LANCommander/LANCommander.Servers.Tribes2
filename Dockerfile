# syntax=docker/dockerfile:1.7

# Override to build against a locally built base, e.g. lancommander/wine:local
ARG BASE_IMAGE=lancommander/wine:latest
FROM ${BASE_IMAGE}

# ----------------------------
# Server settings
#   - The game files are not downloadable; put a Tribes 2 (25034) install in /config/Server, or
#     set T2_ARCHIVE_URL to a zip of one. Server/ is the folder that contains GameData/
#   - T2_MOD is the mod folder under GameData (Classic, or base for the stock game); it must
#     match what clients launch with
#   - The T2_* settings below are written into <mod>/prefs/lancommander.cs on every start and
#     loaded with -serverprefs (empty settings are left alone)
#   - The server runs headless: with an X display (Xvfb) -dedicated hangs before loading any
#     script, so WINE_XVFB is off
# ----------------------------
ENV T2_ARCHIVE_URL="" \
    T2_MOD="Classic" \
    T2_MAP="Katabatic" \
    T2_MISSION_TYPE="CTF" \
    T2_PORT="28000" \
    T2_SERVER_NAME="Tribes 2 Server" \
    T2_SERVER_INFO="" \
    T2_MAX_PLAYERS="32" \
    T2_PASSWORD="" \
    T2_ADMIN_PASSWORD="" \
    T2_SUPER_ADMIN_PASSWORD="" \
    T2_TIME_LIMIT="" \
    T2_BOTS_ENABLED="" \
    T2_BOT_COUNT="" \
    T2_TEAM_DAMAGE="" \
    WINE_XVFB="false" \
    START_EXE="/usr/local/bin/t2-server" \
    START_ARGS=""

COPY Scripts/t2-server /usr/local/bin/t2-server
RUN chmod +x /usr/local/bin/t2-server

COPY Hooks/ "${BASE_HOOKS}/"

# 28000/udp: game, server queries and LAN browser broadcasts (T2_PORT)
EXPOSE 28000/udp

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]
