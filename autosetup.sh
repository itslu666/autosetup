#!/bin/bash

# update the system
os=$(grep ^ID= /etc/os-release | cut -d'=' -f2 | tr -d '"')
declare -A package_manager
package_manager=(
    [arch]="pacman"
    [debian]="apt"
    [ubuntu]="apt"
    [fedora]="dnf"
)

if [[ -n "$(package_manager[$os])" ]]; then
    echo "upgrading system..."
    case "${package_manager[$os]}" in
        pacman)
            sudo pacman -Syu
            ;;
        apt)
            sudo apt update && sudo apt upgrade -y
            ;;
        dnf)
            sudo dnf upgrade --refresh -y
            ;;
    esac
else
    echo "Unable to find package manager (not pacman, apt or dnf), you may want to file an issue."
    exit 0
fi

function install_git() {
    echo "Installing git"
    case "${package_manager[$os]}" in
        pacman)
            sudo pacman -S --needed git
            ;;
        apt)
            sudo apt install -y git
            ;;
        dnf)
            sudo dnf install -y git
            ;;
    esac
}

function install_yay() {
    git clone
}

if [ -z "$1" ]; then
