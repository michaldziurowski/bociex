#!/usr/bin/env bash
#
# docker-net-reset.sh
#
# WHY THIS EXISTS:
# On Linux (notably Arch), some VPN clients (e.g. AWS VPN / OpenVPN)
# modify routing tables, firewall rules, or MTU settings.
# This can break Docker's bridge networking (docker0),
# causing containers to lose outbound internet access.
#
# SYMPTOMS:
# - Containers cannot access the internet
# - DNS or HTTPS requests time out inside containers
# - `go run` / `go mod download` fails with i/o timeout
# - Restarting Docker alone does NOT help
# - Rebooting the machine DOES help
#
# WHAT THIS DOES:
# - Stops Docker
# - Removes the broken docker0 bridge
# - Lets Docker recreate networking cleanly on startup
#
# This avoids a full system reboot.
#

set -euo pipefail

echo "Stopping Docker..."
sudo systemctl stop docker

# docker0 may or may not exist; ignore errors
echo "Removing docker0 bridge if present..."
sudo ip link set docker0 down 2>/dev/null || true
sudo ip link del docker0 2>/dev/null || true

echo "Starting Docker..."
sudo systemctl start docker

echo "Docker network reset complete."
echo "Containers should now have internet access again."
