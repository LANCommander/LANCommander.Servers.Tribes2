# Tribes 2 Server (Docker)

This repository provides a Dockerized **Tribes 2** dedicated server. Tribes 2 (Dynamix, 2001) has a Linux port that is long unmaintained and cannot run the TribesNext-patched game, so the image runs the Windows game's own `-dedicated` mode under Wine.
The image builds on [`lancommander/wine`](https://github.com/LANCommander/LANCommander.Servers.WINE). It supports file overlaying using OverlayFS.

---

## Features

- Runs the retail game (patch 25034, TribesNext) in `-dedicated -nologin` (LAN) mode, with a mod such as **Classic**
- Server name, map, mission type, player limit and passwords are environment variables, written into a generated server prefs file
- Headless: no display or Xvfb needed
- The server console (`console.log`) goes to `docker logs`
- Supports file overlaying using OverlayFS (no file copying required)

## Docker Compose Example

```yaml
services:
  tribes2:
    image: lancommander/tribes2:latest
    container_name: tribes2

    ports:
      - "28000:28000/udp"

    volumes:
      - ./config:/config

    environment:
      T2_MOD: "Classic"
      T2_MAP: "Katabatic"
      T2_MISSION_TYPE: "CTF"
      T2_SERVER_NAME: "My Tribes 2 Server"
      T2_ADMIN_PASSWORD: "secret"

    user: root
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined

    restart: unless-stopped
```

The in-game LAN browser finds servers by broadcast. That needs the container on the LAN itself (macvlan/ipvlan, or `network_mode: host`); with port mapping, clients join by IP.

---

## Game Files

Tribes 2 is retail software with no public download. You must provide an install patched to **25034** (TribesNext RC2 is fine), with the mod you want to run in `GameData/`:

- copy the game folder (the one containing `GameData/Tribes2.exe`) to `config/Server/`, **or**
- set `T2_ARCHIVE_URL` to a zip of that folder, e.g. a LANCommander archive. It is downloaded and extracted on first start, if `Server/GameData/Tribes2.exe` doesn't exist yet.

Clients must run the same mod (`T2_MOD`) in LAN mode, e.g. `Tribes2.exe -nologin -mod Classic` (the install's `Classic_LAN.bat`).

## Directory Layout (Host)

```text
.
└── config/
    ├── Server/            # Tribes 2 install (GameData/Tribes2.exe, GameData/base/*.vl2 ...)
    ├── Overlay/           # Your files, layered on top of Server/ (prefs, autoexec.cs, console.log and new missions land here)
    ├── Merged/            # Overlayfs merged view (auto-created, the server runs here)
    ├── wineprefix/        # Wine prefix (auto-created)
    └── Scripts/
        └── Hooks/         # PowerShell scripts run at container lifecycle hooks
```

---

## Environment Variables

These are in addition to the [WINE image's variables](https://github.com/LANCommander/LANCommander.Servers.WINE#environment).
The `T2_*` server settings are written to `GameData/<T2_MOD>/prefs/lancommander.cs` on every start. That file loads the game's own `prefs/ServerPrefs.cs` first, and settings left empty are not touched, so you can set them in `ServerPrefs.cs` instead.

| Variable | Description | Default |
|----------|-------------|---------|
| `T2_MOD` | Mod folder under `GameData` (`-mod`). `base` runs the stock game | `Classic` |
| `T2_MAP` | Mission to start (`$Host::Map`) | `Katabatic` |
| `T2_MISSION_TYPE` | Game type of that mission (`$Host::MissionType`): `CTF`, `CnH`, `DM`, `Siege`, `Hunters`, `TeamHunters`, `Bounty`, `Rabbit`, `DnD` ... | `CTF` |
| `T2_PORT` | Game port (`$Host::Port`) | `28000` |
| `T2_SERVER_NAME` | `$Host::GameName` | `Tribes 2 Server` |
| `T2_SERVER_INFO` | `$Host::Info`, shown in the server info dialog | |
| `T2_MAX_PLAYERS` | `$Host::MaxPlayers` | `32` |
| `T2_PASSWORD` | Join password (`$Host::Password`) | |
| `T2_ADMIN_PASSWORD` | `$Host::AdminPassword` | |
| `T2_SUPER_ADMIN_PASSWORD` | `$Host::ClassicSuperAdminPassword` (Classic only) | |
| `T2_TIME_LIMIT` | Minutes per map (`$Host::TimeLimit`) | |
| `T2_BOTS_ENABLED` | `1` to fill with bots (`$Host::BotsEnabled`) | |
| `T2_BOT_COUNT` | `$Host::BotCount` | |
| `T2_TEAM_DAMAGE` | `1` turns on team damage (`$Host::TeamDamageOn`) | |
| `T2_ARCHIVE_URL` | Zip of the game folder, used if `Server/GameData/Tribes2.exe` is missing | |
| `WINE_XVFB` | Leave off: with an X display the dedicated server hangs at startup | `false` |
| `START_EXE` | Launcher | `/usr/local/bin/t2-server` |
| `START_ARGS` | Added to the `Tribes2.exe` command line (before `-mod`) | |

See [Documentation/Docker.md](Documentation/Docker.md) for more detail.

---

## Building

The image is built `FROM lancommander/wine:latest` by default. To build against a local base image:

```bash
docker build --build-arg BASE_IMAGE=lancommander/wine:local -t lancommander/tribes2:local .
```

---

## License

Tribes 2, TribesNext and Wine are distributed under their respective licenses.
This repository contains only Docker build logic and helper scripts licensed under MIT.
