#!/bin/bash

set -euo pipefail

username="<username>"

sudo pacman -Syu --needed --noconfirm go git
mkdir /home/$username/tmp
git clone https://aur.archlinux.org/yay.git /home/$username/tmp/yay
export GOCACHE="/home/$username/.cache/go-build" && cd /home/$username/tmp/yay && makepkg -sri --noconfirm
rm -rf /home/$username/tmp/yay
