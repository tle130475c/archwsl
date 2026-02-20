#!/usr/bin/env bash

set -e

rootpass="<rootpass>"

username="<username>"
realname="<realname>"
userpass="<userpass>"

# Configure mirrorlist
printf "Server = https://mirror.xtom.com.hk/archlinux/\$repo/os/\$arch\n" > /etc/pacman.d/mirrorlist
printf "Server = https://arch-mirror.wtako.net/\$repo/os/\$arch\n" >> /etc/pacman.d/mirrorlist
printf "Server = https://mirror-hk.koddos.net/archlinux/\$repo/os/\$arch\n" >> /etc/pacman.d/mirrorlist

# Time zone
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

# Configure localization
printf "en_US.UTF-8 UTF-8\n" > /etc/locale.gen
printf "LANG=en_US.UTF-8\n" > /etc/locale.conf
printf "KEYMAP=us\n" > /etc/vconsole.conf
locale-gen

# Core tools
pacman -Syu --needed --noconfirm bash-completion sudo base-devel fuse2 xdg-utils

# Root password
echo -e "${rootpass}\n${rootpass}" | passwd

# Add new user
useradd -G wheel,audio,lp,optical,storage,disk,video,power,render -s /bin/bash -m $username -d /home/$username -c "$realname"
echo -e "${userpass}\n${userpass}" | passwd $username

# Disable sudo password prompt timeout
printf "\n## Disable password prompt timeout\n" >> /etc/sudoers
printf "Defaults passwd_timeout=0\n" >> /etc/sudoers

# Disable sudo timestamp timeout
printf "\n## Disable sudo timestamp timeout\n" >> /etc/sudoers
printf "Defaults timestamp_timeout=-1\n" >> /etc/sudoers

# Allow members of wheel group to execute any command
linum=$(sed -n "/^# %wheel ALL=(ALL:ALL) ALL$/=" /etc/sudoers)
sed -i "${linum}s/^# //" /etc/sudoers

# Core programming tools
pacman -Syu --needed --noconfirm git github-cli emacs-wayland

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
