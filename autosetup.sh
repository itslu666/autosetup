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

if [[ -n "$(package_manager[$os])" ]] && [[ ! " $@ " =~ " --skip-upgrade " ]]; then
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
        echo "installing curl..."
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

    echo "installing zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

function install_zsh_plugins() {
    echo "installing zsh plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

    sed -i '/^plugins=(/s/\(git\)/\1 zsh-autosuggestions zsh-syntax-highlighting/' ~/.zshrc
    source ~/.zshrc
}

# only install yay if arch os
if [[ "$os" == "arch" ]] && [[ ! " $@ " =~ " --skip-yay " ]]; then
    install_git
    install_yay
fi

if [[ ! " $@ " =~ " --skip-zsh " ]]; then
    install_zsh

    read -p "Install zsh-autosuggestions & zsh-syntax-highlighting? [Y/n]: " choice
    choice=${choice:-Y}

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        install_zsh_plugins
    fi