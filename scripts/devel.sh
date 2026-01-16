#!/bin/bash

mkdir -p ~/devel

omarchy-install-dev-env go
omarchy-install-dev-env node

curl -fsSL https://claude.ai/install.sh | bash

sudo pacman -S --noconfirm --needed tree
sudo pacman -S --noconfirm --needed strace
