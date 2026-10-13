# Minecraft Server in Docker

A self-built Docker image and Docker Compose setup for running the official Minecraft Java Edition server.

## Table of Contents

- [Description](#description)
- [Quickstart](#quickstart)
  - [Prerequisites](#prerequisites)
  - [Start the Server](#start-the-server)
  - [Connect to the Server](#connect-to-the-server)
- [Repository Contents](#repository-contents)
- [Usage](#usage)
  - [How It Works](#how-it-works)
  - [Configuration with the .env File](#configuration-with-the-env-file)
  - [Accepting the EULA](#accepting-the-eula)
  - [Changing the Port](#changing-the-port)
  - [Updating the Minecraft Version](#updating-the-minecraft-version)
  - [Persistence](#persistence)
  - [Restart Behaviour](#restart-behaviour)
  - [Useful Commands](#useful-commands)
- [Testing](#testing)
- [Security Notes](#security-notes)

## Description

This repository contains everything needed to run a Minecraft Java Edition server with Docker.

The Docker image is built from the official Java 25 runtime image (`eclipse-temurin:25-jre`), so no prebuilt Minecraft image is used. During the build, the official `server.jar` is downloaded from Mojang. A small start script turns environment variables into the server configuration (`server.properties`).

All configuration comes from outside the container, from a local `.env` file. Docker Compose starts the server on a configurable port (default **8888**), stores the world in a persistent volume and restarts the container automatically if it crashes.

The purpose of this project is to describe the whole server as code, so it can be started on any machine with Docker in a reproducible way.

## Quickstart

### Prerequisites

- A Linux machine or cloud VM with at least **2 GB of free RAM**
- **Docker Engine** and the **Docker Compose plugin** (`docker compose version`)
- The server port (default **8888/TCP**) open in the firewall of the VM / cloud provider
- Internet access during the build (to download the server from Mojang)

### Start the Server

```bash
# 1. Clone the repository
git clone <repository-url>
cd minecraft-server-docker

# 2. Create your configuration from the template
cp .env.example .env

# 3. Read the Minecraft EULA and accept it in .env: EULA=true
nano .env

# 4. Build the image and start the server in the background
docker compose up -d --build

# 5. Follow the logs until "Done (...)! For help, type "help"" appears
docker compose logs -f mc-server
```

Press `Ctrl+C` to leave the logs. The server keeps running.

### Connect to the Server

In Minecraft Java Edition: **Multiplayer → Add Server** → Server Address: `<VM-IP>:8888`

## Repository Contents

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the image: Java base image, installs `curl`, downloads the official `server.jar`, sets default values. |
| `entrypoint.sh` | Start script of the container: checks the EULA, writes the environment variables into `server.properties` and starts the server. |
| `docker-compose.yaml` | Defines the `mc-server` service with port, volume, restart policy and the `.env` file. |
| `.env.example` | Template for the configuration. Copy it to `.env` and adjust the values. `.env` itself is not committed. |
| `.gitignore` | Keeps secrets (`.env`, keys), server data and editor files out of the repository. |
| `.dockerignore` | Keeps files that are not needed in the image (e.g. `.git`, `.env`, documentation) out of the build context. |
| `checklist.md` | Copy of the project checklist. |
| `README.md` | This documentation. |
| `checklist.pdf` | Original project checklist (PDF). |

## Usage

### How It Works

```
.env ──► docker compose up --build
                │
                ▼
Dockerfile ──► eclipse-temurin:25-jre + curl
           ──► downloads server.jar to /opt/minecraft
           ──► sets default values (ENV)
                │
                ▼
entrypoint.sh ──► checks EULA=true
              ──► writes server.properties from the environment variables
              ──► exec java -jar /opt/minecraft/server.jar
                │
                ▼
HOST_PORT (host) ──► 25565 (container)     Volume mc-data ──► /data (world + config)
```

The server runs in the folder `/data`. Everything the server writes there (world, configuration, logs) is stored in the volume. The `server.jar` itself is part of the image (`/opt/minecraft`).

### Configuration with the .env File

All settings are configured in the `.env` file (created from `.env.example`). Docker Compose loads it with `env_file`. Nothing is hardcoded in `docker-compose.yaml`.

| Variable | Default | Description | Possible values |
|---|---|---|---|
| `EULA` | `false` | Accepts the Minecraft EULA. Must be set to `true` explicitly. | `true`, `false` |
| `HOST_PORT` | `8888` | Port on the host that players connect to | any free port |
| `MEMORY` | `1536M` | RAM for the server (Java `-Xms` / `-Xmx`) | e.g. `1G`, `1536M`, `2G` |
| `MOTD` | `Minecraft Server` | Text shown in the server list | any text |
| `DIFFICULTY` | `easy` | Difficulty | `peaceful`, `easy`, `normal`, `hard` |
| `GAMEMODE` | `survival` | Game mode for new players | `survival`, `creative`, `adventure`, `spectator` |
| `MAX_PLAYERS` | `10` | Maximum number of players online | number |
| `WHITE_LIST` | `false` | Only players on the whitelist can join | `true`, `false` |

**Example – a creative server for 5 players:**

Change these lines in `.env`:

```dotenv
GAMEMODE=creative
DIFFICULTY=peaceful
MAX_PLAYERS=5
```

Apply the change (no rebuild needed):

```bash
docker compose up -d
```

The start script rewrites `server.properties` on every start, so the values in `.env` are always the ones the server uses.

**Adding a new setting** (e.g. `pvp`):

1. `Dockerfile`: add a default value, e.g. `PVP=true`, to the `ENV` block
2. `entrypoint.sh`: add the line `pvp=${PVP}` inside the `server.properties` block
3. `.env.example` and `.env`: add `PVP=false`
4. Rebuild: `docker compose up -d --build`

### Accepting the EULA

The Minecraft server only runs if you accept the [Minecraft EULA](https://aka.ms/MinecraftEULA). This is **not** done automatically: the default value is `EULA=false`.

Read the EULA and then set in `.env`:

```dotenv
EULA=true
```

If `EULA` is not `true`, the container stops with a message in the logs (`docker compose logs mc-server`).

### Changing the Port

Players connect on `HOST_PORT` (default `8888`). Inside the container the server always listens on `25565`. To use another port, change it in `.env`:

```dotenv
HOST_PORT=25565
```

Then run `docker compose up -d` and open the new port in the firewall.

### Updating the Minecraft Version

The download link of the server is set as a build argument in the `Dockerfile`:

```dockerfile
ARG SERVER_JAR_URL=https://piston-data.mojang.com/v1/objects/.../server.jar
```

1. Copy the new link from the [official download page](https://www.minecraft.net/de-de/download/server)
2. Replace the value of `SERVER_JAR_URL`
3. Rebuild the image:

```bash
docker compose build --no-cache
docker compose up -d
```

> Make a backup of the world before updating. A world opened with a newer version cannot be opened with an older one.

### Persistence

The named volume `mc-data` is mounted to `/data`. The world, `server.properties`, the whitelist and the operator list are stored there and survive container restarts, `docker compose down` and image rebuilds.

Create a backup of the volume (Docker Compose puts the project folder name in front of the volume name, check it with `docker volume ls`):

```bash
docker run --rm -v minecraft-server-docker_mc-data:/data -v "$(pwd)":/backup ubuntu \
  tar czf /backup/mc-backup.tar.gz -C /data .
```

> **Warning:** `docker compose down -v` deletes the volume and therefore the world.

### Restart Behaviour

The service uses `restart: unless-stopped`. Docker restarts the container automatically when the server stops because of an error or after a reboot of the machine. It is only not restarted when it was stopped manually (`docker compose stop`).

### Useful Commands

| Command | Description |
|---|---|
| `docker compose up -d --build` | Build the image and start the server |
| `docker compose up -d` | Apply changes from `.env` or `docker-compose.yaml` |
| `docker compose ps` | Show status and ports |
| `docker compose logs -f mc-server` | Follow the server logs |
| `docker compose restart mc-server` | Restart the server |
| `docker compose down` | Stop and remove the container (the world stays in the volume) |
| `docker compose exec mc-server cat /data/server.properties` | Show the current server configuration |

## Testing

**1. The server is running:**

```bash
docker compose ps
```

The status must be `Up` and the ports `0.0.0.0:8888->25565/tcp`.

**2. The server is reachable** (from another computer, with [mcstatus](https://github.com/py-mine/mcstatus)):

```bash
python3 -m venv venv
source venv/bin/activate
pip install mcstatus
mcstatus <VM-IP>:8888 status
```

The output shows the version, the MOTD and the number of players.

**3. The data is kept after a restart:**

```bash
docker compose exec mc-server touch /data/test-persistence.txt
docker compose down
docker compose up -d
docker compose exec mc-server ls /data/test-persistence.txt
```

The file still exists in the new container.

**4. The container restarts automatically after an error:**

```bash
docker inspect -f '{{.RestartCount}}' mc-server
docker compose exec mc-server kill 1
sleep 15
docker compose ps
docker inspect -f '{{.RestartCount}}' mc-server
```

The server process is stopped without `docker stop`. Docker starts the container again and the restart counter increases by one.

## Security Notes

- No passwords, tokens, usernames, IP addresses or SSH keys are stored in this repository.
- The configuration is loaded from `.env`, which is excluded by `.gitignore` and `.dockerignore`.
- The EULA is never accepted automatically; the user has to set `EULA=true` explicitly.
- `online-mode` stays enabled (server default), so only players with a valid Minecraft account can join.
- For a private server, set `WHITE_LIST=true` and add players in the server console with `whitelist add <name>`.