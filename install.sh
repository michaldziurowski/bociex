#!/bin/bash


find scripts/ -type f -exec chmod +x {} \;

find bin/ -type f -exec chmod +x {} \;


./scripts/browser.sh
./scripts/direnv.sh
./scripts/fix_screenrecord.sh
./scripts/keyring.sh
./scripts/net-cli.sh
./scripts/nordvpn.sh
./scripts/printer.sh
./scripts/ssh.sh
./scripts/tailscale.sh
./scripts/devel.sh
./scripts/aws.sh
./scripts/yazi.sh
./scripts/theme.sh
./scripts/extras/awsvpnclient.sh
./scripts/extras/slack.sh
./scripts/extras/k9s.sh
./scripts/extras/terraform.sh
./scripts/stow.sh

./scripts/hypr.sh



