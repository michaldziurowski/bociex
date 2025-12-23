#!/bin/bash

sudo pacman -S --noconfirm --needed stow

echo "Running stow..."

# stow doesnt override files if they already exist so we have to move existing ones
# it only moves files if destination doesnt already exist (only move at first run)
[ ! -e ~/.bashrc.backup ] && mv ~/.bashrc ~/.bashrc.backup
[ ! -e ~/.config/nvim.backup ] && mv ~/.config/nvim ~/.config/nvim.backup
[ ! -e ~/.config/ghostty/config.backup ] && mv ~/.config/ghostty/config ~/.config/ghostty/config.backup
[ ! -e ~/.config/starship.toml.backup ] && mv ~/.config/starship.toml ~/.config/starship.toml.backup
[ ! -e ~/.config/hypr/hypridle.conf.backup ] && mv ~/.config/hypr/hypridle.conf ~/.config/hypr/hypridle.conf.backup

stow -t ~ configs
