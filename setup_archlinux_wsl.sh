#!/usr/bin/env bash

set -euo pipefail

root_password="<rootpass>"
username="<username>"
realname="<realname>"
user_password="<userpass>"

run_command_as_user() {
    local command="$1"
    sudo -u "$username" bash -c "export HOME=/home/$username && $command"
}

retry() {
    local max_attempts=5
    local delay=30
    local attempt=1
    while true; do
        "$@" && return 0
        if ((attempt >= max_attempts)); then
            printf "Command failed after %d attempts: %s\n" "$max_attempts" "$*" >&2
            return 1
        fi
        printf "Attempt %d/%d failed. Retrying in %ds...\n" "$attempt" "$max_attempts" "$delay" >&2
        ((attempt++))
        sleep "$delay"
    done
}

retry_as_user() {
    retry run_command_as_user "$1"
}

# ── Logging setup ─────────────────────────────────────────────────────────────
LOG_FILE="/root/archwsl_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
log() { printf "\n[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
trap 'printf "[%s] FAILED at line %d: %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$LINENO" "$BASH_COMMAND"' ERR
log "Arch Linux WSL setup started — log file: $LOG_FILE"

log "Configuring mirrorlist"
printf "Server = https://mirror.xtom.com.hk/archlinux/\$repo/os/\$arch\n" > /etc/pacman.d/mirrorlist
printf "Server = https://arch-mirror.wtako.net/\$repo/os/\$arch\n" >> /etc/pacman.d/mirrorlist
printf "Server = https://mirror-hk.koddos.net/archlinux/\$repo/os/\$arch\n" >> /etc/pacman.d/mirrorlist

log "Configuring time zone"
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

log "Configuring localization"
printf "en_US.UTF-8 UTF-8\n" > /etc/locale.gen
printf "LANG=en_US.UTF-8\n" > /etc/locale.conf
printf "KEYMAP=us\n" > /etc/vconsole.conf
locale-gen

log "Disabling makepkg debug"
linum=$(sed -n "/^OPTIONS=(.*)$/=" /etc/makepkg.conf)
sed -i "${linum}s/debug/\!debug/" /etc/makepkg.conf

log "Installing essential packages"
retry pacman -Syu --needed --noconfirm bash-completion sudo base-devel fuse2 xdg-utils man-pages man-db nfs-utils gvim

log "Setting root password"
printf "%s\n%s\n" "$root_password" "$root_password" | passwd

log "Creating user: $username"
useradd -G wheel,audio,lp,optical,storage,disk,video,power,render -s /bin/bash -m $username -d /home/$username -c "$realname"
printf "%s\n%s\n" "$user_password" "$user_password" | passwd $username

log "Configuring sudoers"
printf "\n## Disable password prompt timeout\n" >> /etc/sudoers
printf "Defaults passwd_timeout=0\n" >> /etc/sudoers
printf "\n## Disable sudo timestamp timeout\n" >> /etc/sudoers
printf "Defaults timestamp_timeout=-1\n" >> /etc/sudoers
linum=$(sed -n "/^# %wheel ALL=(ALL:ALL) ALL$/=" /etc/sudoers)
sed -i "${linum}s/^# //" /etc/sudoers

log "Granting temporary passwordless sudo for AUR builds"
linum=$(sed -n "/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL$/=" /etc/sudoers)
sed -i "${linum}s/^# //" /etc/sudoers

log "Installing Yay AUR helper"
retry pacman -Syu --needed --noconfirm go git
run_command_as_user "mkdir /home/$username/tmp"
run_command_as_user "git clone https://aur.archlinux.org/yay.git /home/$username/tmp/yay"
run_command_as_user "export GOCACHE='/home/$username/.cache/go-build' && cd /home/$username/tmp/yay && makepkg -sri --noconfirm"

log "Installing fonts"
retry pacman -Syu --needed --noconfirm ttf-dejavu ttf-liberation noto-fonts-emoji ttf-cascadia-code ttf-fira-code ttf-roboto-mono ttf-hack noto-fonts-cjk

log "Installing general tools"
retry pacman -Syu --needed --noconfirm expect pacman-contrib 7zip unarchiver bash-completion tree rclone rsync pdftk texlive texlive-lang lftp

log "Installing programming tools"
retry pacman -Syu --needed --noconfirm git github-cli git-lfs valgrind emacs-wayland bash-language-server azcopy azure-cli aws-cli-v2 jq
retry_as_user "yay -Syu --needed --noconfirm claude-code databricks-cli-bin"

log "Installing Docker"
retry pacman -Syu --needed --noconfirm docker docker-compose docker-buildx minikube kubectl helm
systemctl disable --now systemd-networkd-wait-online.service
systemctl enable docker.service
usermod -aG docker $username

log "Installing Java"
retry pacman -Syu --needed --noconfirm jdk-openjdk openjdk-doc openjdk-src maven gradle gradle-doc

log "Installing Python"
retry pacman -Syu --needed --noconfirm python uv

log "Installing JavaScript tools"
retry pacman -Syu --needed --noconfirm nvm eslint prettier
run_command_as_user "printf '\n## nvm configuration\n' >> /home/$username/.bashrc"
run_command_as_user "printf 'source /usr/share/nvm/init-nvm.sh\n' >> /home/$username/.bashrc"

log "Revoking temporary passwordless sudo"
linum=$(sed -n "/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL$/=" /etc/sudoers)
sed -i "${linum}s/^/# /" /etc/sudoers

log "Cleaning GnuPG lock files"
run_command_as_user "rm -f /home/$username/.gnupg/public-keys.d/.#lk*"
run_command_as_user "rm -f /home/$username/.gnupg/public-keys/pubring.db.lock"

log "Arch Linux WSL setup completed successfully"
