#!/usr/bin/env bash

set -e

USERNAME="$1"
PASSWORD="$2"
SERVER_IP="$3"
FINGERPRINTS="$4"

HETZNER_API_BASE_URL="${HETZNER_INSTALLIMAGE_ROBOT_API_BASE_URL}"
REBOOT_PAUSE="${HETZNER_INSTALLIMAGE_REBOOT_PAUSE}"
WAIT_FOR_HOST="${HETZNER_INSTALLIMAGE_WAIT_FOR_HOST}"

echo "Checking current rescue mode state for $SERVER_IP..."
RESCUE_STATE=$(curl -s -u $USERNAME:$PASSWORD "$HETZNER_API_BASE_URL/boot/$SERVER_IP/rescue")

if [[ $(echo "$RESCUE_STATE" | grep '"active":true') ]]; then
  echo "Rescue mode is already active for $SERVER_IP. Skipping activation."
  return 0
fi

echo "Composing rescue request body for $SERVER_IP..."
RESCUE_REQUEST=$(jq -n \
  --arg os "linux" \
  --arg arch "64" \
  --arg key "$FINGERPRINTS" \
  '{os: $os, arch: $arch, authorized_key: $key}')

echo "Activating rescue mode for $SERVER_IP..."
curl -s -X POST -u $USERNAME:$PASSWORD \
  -d "$(echo $RESCUE_REQUEST | jq -r @uri)" \
  "$HETZNER_API_BASE_URL/boot/$SERVER_IP/rescue"

echo "Executing hardware reset for $SERVER_IP..."
curl -s -X POST -u $USERNAME:$PASSWORD \
  -d "type=hw" \
  "$HETZNER_API_BASE_URL/reset/$SERVER_IP"

echo "Removing $SERVER_IP from local known_hosts file..."
ssh-keygen -R "$SERVER_IP"

echo "Pausing for hardware reset to kick in for $SERVER_IP..."
sleep $REBOOT_PAUSE

echo "Waiting for $SERVER_IP to come back online..."
timeout 180 bash -c \
  "until nc -zv $WAIT_FOR_HOST 22; do sleep 1; done"

echo "$SERVER_IP is back online."
