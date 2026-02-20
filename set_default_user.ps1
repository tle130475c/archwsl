#Requires -Version 5.1

$username = "<username>"

wsl --manage archlinux --set-default-user $username
