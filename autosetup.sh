#!/bin/bash

cd ~

# update the system
os=$(grep ^ID= /etc/os-release | cut -d'=' -f2 | tr -d '"')
declare -A package_manager
package_manager=(
    [arch]="pacman"
    [debian]="apt"
    [ubuntu]="apt"
    [fedora]="dnf"
)

# check if OS is recognised 
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

function check_installed() {
    if ! command -v $1 &> /dev/null; then
        echo "installing $1..."
        case "${package_manager[$os]}" in
            pacman)
                sudo pacman -S --needed $1
                ;;
            apt)
                sudo apt update && sudo apt install -y $1
                ;;
            dnf)
                sudo dnf install -y $1
                ;;
        esac
    fi
}

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

function install_yay() {
    echo "installing yay..."
    sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
}

function install_zsh() {
    # check if curl is installed
    check_installed "curl"

    echo "installing zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

function install_zsh_plugins() {
    echo "installing zsh plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    git clone https://github.com/wting/autojump
    cd autojump
    ./install.py
    cd ~
    rm -rf autojump

    sed -i '/^plugins=(/s/\(git\)/\1 zsh-autosuggestions zsh-syntax-highlighting autojump/' ~/.zshrc
    source ~/.zshrc
}

function install_zsh_starship() {
    # check if curl is installed
    check_installed "curl"

    echo "installing starship..."
    curl -sS https://starship.rs/install.sh | sh
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
}

function install_nano_syntax_highlighting() {
    # check if nano is installed
    check_installed "nano"

    echo "installing nano syntax highlighting..."
    git clone https://github.com/scopatz/nanorc.git
    cp -r nanorc/*.nanorc .nano
    echo "include .nano/*.nanorc" >> ~/.nanorc

    read -p "Install nano syntax highlighting for sudo too? [Y/n]: " choice
    choice=${choice:-Y}

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        sudo cp -r nanorc/*.nanorc /usr/share/nano
        sudo echo "include /usr/share/nano/*.nanorc" >> /etc/nanorc
    fi
}

function install_wezterm_fonts() {
    check_installed "wezterm"
    check_installed "unzip"

    mkdir temp
    # jetbrains
    wget https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip
    unzip JetBrainsMono-2.304.zip -d temp
    sudo mkdir -p /usr/share/fonts/JettBrainsMono
    sudo cp -r temp/fonts/ttf/* /usr/share/fonts/JettBrainsMono
    rm -rf temp

    mkdir temp
    # nerdfont (caskaydiacove)
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip
    unzip CascadiaCode.zip -d temp
    sudo mkdir -p /usr/share/fonts/CaskaydiaCove
    sudo cp temp/*.ttf /usr/share/fonts/CaskaydiaCove
    rm -rf temp

    mkdir temp
    # noto color emoji
    wget https://github.com/googlefonts/noto-emoji/blob/main/fonts/NotoColorEmoji.ttf
    sudo cp temp/NotoColorEmoji.ttf /usr/share/fonts
    rm -rf temp
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
fi

if [[ ! " $@ " =~ " --skip-nano-synhigh " ]]; then
    install_nano_syntax_highlighting
fi

if [[ "$os" == "arch" ]] && [[ ! " $@ " =~ " --skip-pacman-color " ]]; then
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
fi

if [[ ! " $@ " =~ " --skip-zsh-starship " ]]; then
    install_zsh_starship
fi

if [[ ! " $@ " =~ " --skip-wezterm " ]]; then
    install_wezterm_fonts
fi