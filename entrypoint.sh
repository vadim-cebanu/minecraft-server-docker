#!/bin/bash
set -e

# The user must accept the Minecraft EULA explicitly
if [ "${EULA}" != "true" ]; then
    echo "ERROR: You must accept the Minecraft EULA (https://aka.ms/MinecraftEULA)."
    echo "Set EULA=true in your .env file."
    exit 1
fi
echo "eula=true" > eula.txt

# Write the settings from the environment variables into server.properties
cat > server.properties <<EOF
server-port=25565
motd=${MOTD}
difficulty=${DIFFICULTY}
gamemode=${GAMEMODE}
max-players=${MAX_PLAYERS}
white-list=${WHITE_LIST}
EOF

# Start the server (exec: Java receives the stop signal and saves the world)
exec java -Xms${MEMORY} -Xmx${MEMORY} -jar /opt/minecraft/server.jar --nogui