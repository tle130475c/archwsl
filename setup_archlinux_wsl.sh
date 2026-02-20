#!/usr/bin/env bash

set -e

rootpass="<rootpass>"

username="<username>"
realname="<realname>"
userpass="<userpass>"

# Core tools
pacman -Syu --needed --noconfirm bash-completion sudo base-devel fuse2 xdg-utils

# Time zone
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

# Localization
linum=$(sed -n '/^#en_US.UTF-8 UTF-8  $/=' /etc/locale.gen)
sed -i "${linum}s/^#//" /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Root password
echo -e "${rootpass}\n${rootpass}" | passwd

# Add new user
useradd -G wheel,audio,lp,optical,storage,disk,video,power,render -s /bin/bash -m $username -d /home/$username -c "$realname"
echo -e "${userpass}\n${userpass}" | passwd $username

# Allow user in wheel group execute any command
linum=$(sed -n "/^# %wheel ALL=(ALL:ALL) ALL$/=" /etc/sudoers)
sed -i "${linum}s/^# //" /etc/sudoers

# Reduce the number of times re-enter password using sudo
sed -i "$(sed -n "/^# Defaults\!.*/=" /etc/sudoers | tail -1) a Defaults timestamp_timeout=20" /etc/sudoers

# Core programming tools
pacman -Syu --needed --noconfirm git github-cli

# Java
pacman -Syu --needed --noconfirm jdk21-openjdk maven

# Javascript
pacman -Syu --needed --noconfirm eslint prettier nvm

# Python
pacman -Syu --needed --noconfirm uv

# Docker
pacman -Syu --needed --noconfirm docker docker-compose docker-buildx minikube kubectl helm
systemctl disable --now systemd-networkd-wait-online.service
systemctl enable docker.service
usermod -aG docker $username
