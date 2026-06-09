#!/usr/bin/env bash
# Host bootstrap that must happen before manifest-driven installs can run.

# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/common.sh"

bootstrap_package_manager() {
    case "$(detect_distro)" in
        macos)
            if have brew; then
                log_ok "homebrew already installed"
            else
                log_step "bootstrap :: homebrew"
                NONINTERACTIVE=1 /bin/bash -c \
                    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi

            if [ -x /opt/homebrew/bin/brew ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [ -x /usr/local/bin/brew ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
            ;;
        debian)
            log_step "bootstrap :: apt prerequisites"
            sudo apt-get update
            sudo apt-get install -y curl ca-certificates locales unzip git
            if ! locale -a | grep -qx 'en_US.utf8'; then
                sudo sed -i 's/^# *en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/' /etc/locale.gen
                sudo locale-gen en_US.UTF-8
            fi
            sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
            ;;
        fedora)
            log_ok "fedora dnf available"
            ;;
        amazon)
            log_ok "amazon linux dnf/yum available"
            ;;
    esac
}
