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

# git install func
function install_git() {
    echo "Installing git..."
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

# yay install func
function install_yay() {
    echo "installing yay..."
    sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
    echo "Successfully installed yay"
}

# zsh instal func
function install_zsh() {
    if ! command -v curl &> /dev/null; then
        if [[ -n "$(package_manager[$os])" ]]; then
            case "${package_manager[$os]}" in
                pacman)
                    sudo pacman -S --needed curl
                    ;;
                apt)
                    sudo apt update && sudo apt install -y curl
                    ;;
                dnf)
                    sudo dnf install -y curl
                    ;;
            esac
        else
            echo "Curl is not installed and the package manager was not recognized. Install curl manually."
            exit 0
        fi
    fi
    
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

if [ -z "$1" ]; then
    # only install yay if arch os
    if [[ "$os" == "arch" ]] && [[ ! " $@ " =~ " --skip-yay " ]]; then
        install_git
        install_yay
    fi