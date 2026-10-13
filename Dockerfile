# Official Java 25 runtime image (no prebuilt Minecraft image)
FROM eclipse-temurin:25-jre

# Download link of the official server.jar from minecraft.net
ARG SERVER_JAR_URL=https://piston-data.mojang.com/v1/objects/33680f5f2ac32864d6d7cf5e56a705fdb3e05f4c/server.jar

# Install curl to download the server
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Working directory for the server program (created automatically)
WORKDIR /opt/minecraft

# Download the server into the working directory
RUN curl -fsSL -o server.jar "${SERVER_JAR_URL}"

# Start script
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# Default values - the EULA must be accepted explicitly by the user
ENV EULA=false \
    MEMORY=1536M \
    MOTD="Minecraft Server" \
    DIFFICULTY=easy \
    GAMEMODE=survival \
    MAX_PLAYERS=10 \
    WHITE_LIST=false

# Working directory for the server data (world, config) - mounted as volume
WORKDIR /data
EXPOSE 25565

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]