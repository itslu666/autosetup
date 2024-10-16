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
if [[ -n "${package_manager[$os]}" ]]; then
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
    exit 1
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
    if ! command -v "yay" &> /dev/null; then
        echo "installing yay..."
        sudo pacman -S --needed base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si
        cd ..
        rm -rf yay
    fi
}

function install_wezterm() {
    echo "installing wezterm..."
    case "${package_manager[$os]}" in
        pacman)
            sudo pacman -S --needed wezterm
            ;;
        apt)
            curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
            echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
            sudo apt update
            sudo apt install libc6 libssl3 libx11-xcb1 wezterm

            ;;
        dnf)
            sudo dnf install -y https://github.com/wez/wezterm/releases/download/20240203-110809-5046fc22/wezterm-20240203_110809_5046fc22-1.fedora39.x86_64.rpm
            ;;
    esac
}

function install_zsh() {
    # check if curl is installed
    check_installed "curl"
    check_installed "zsh"

    echo "installing zsh..."
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

function install_zsh_plugins() {
    echo "installing zsh plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/wting/autojump
    cd autojump
    ./install.py
    cd ~
    rm -rf autojump

    sed -i '/^plugins=(/s/\(git\)/\1 zsh-autosuggestions zsh-syntax-highlighting autojump/' ~/.zshrc
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
    mkdir .nano
    cp -r nanorc/*.nanorc .nano
    echo "include .nano/*.nanorc" >> ~/.nanorc

    read -p "Install nano syntax highlighting for sudo too? [Y/n]: " choice
    choice=${choice:-Y}

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        sudo cp -r nanorc/*.nanorc /usr/share/nano
        sudo tee -a /etc/nanorc <<< "include /usr/share/nano/*.nanorc"
    fi

    rm -rf nanorc
}

function install_wezterm_fonts() {
    check_installed "wezterm"
    check_installed "unzip"

    local temp_dir=$(mktemp -d)

    # nerdfont (caskaydiacove)
    echo "Installing CaskayiaCode..."
    case "${package_manager[$os]}" in
        pacman)
            sudo pacman -S --needed ttf-cascadia-code-nerd
            ;;
        apt)
            sudo apt install -y fonts-cascadia-code
            ;;
        dnf)
            sudo dnf install -y cascadia-code-nf-fonts
            ;;
    esac

    # noto color emoji
    echo "Installing noto emoji..."
    case "${package_manager[$os]}" in
        pacman)
            sudo pacman -S --needed noto-fonts-emoji
            ;;
        apt)
            sudo apt install -y fonts-noto-color-emoji
            ;;
        dnf)
            sudo dnf install -y google-noto-emoji-fonts
            ;;
    esac
}

# only install yay if arch os
if [[ "$os" == "arch" ]] && [[ ! " $@ " =~ " --skip-yay " ]]; then
    install_git
    install_yay
fi

if [[ ! " $@ " =~ " --skip-wezterm " ]]; then
    install_wezterm
fi

if [[ ! " $@ " =~ " --skip-nano-synhigh " ]]; then
    install_nano_syntax_highlighting
fi

if [[ "$os" == "arch" ]] && [[ ! " $@ " =~ " --skip-pacman-color " ]]; then
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
fi

if [[ ! " $@ " =~ " --skip-wezterm " ]]; then
    install_wezterm_fonts
fi

if [[ ! " $@ " =~ " --skip-zsh " ]]; then
    install_zsh

    read -p "Install zsh-autosuggestions & zsh-syntax-highlighting? [Y/n]: " choice
    choice=${choice:-Y}

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        install_zsh_plugins
    fi
fi

if [[ ! " $@ " =~ " --skip-zsh-starship " ]]; then
    install_zsh_starship
fi

chsh -s $(which zsh)
exec zsh