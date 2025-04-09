#!/bin/bash

# ======================================================================
echo -e "\n\033[1;36m
  /\_/\  
 ( o.o ) 
  > ^ <
  
  Привет! Я котик-инсталлятор HyprlandUtil!
  Сейчас всё настроим =^..^=
\033[0m"
# ======================================================================

set -e  # Автоматически завершать скрипт при ошибке

# Цвета для удобства
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция проверки установки пакета
is_installed() {
    if pacman -Qi "$1" &>/dev/null || yay -Qi "$1" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Проверяем, установлен ли yay
check_yay() {
    if ! command -v yay &> /dev/null; then
        echo -e "${RED}❌ yay не установлен! Установите его вручную:${NC}"
        echo "git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin && cd /tmp/yay-bin && makepkg -si --noconfirm"
        exit 1
    fi
    echo -e "${GREEN}✅ yay установлен.${NC}"
}

# Установка пакетов через yay с проверкой
install_packages() {
    local packages=(
        visual-studio-code-bin
        zen-browser
        telegram-desktop
        spotify-launcher
        ttf-maple-beta
        nodejs
    )

    echo -e "${YELLOW}🔄 Проверяем и устанавливаем пакеты...${NC}"
    
    for pkg in "${packages[@]}"; do
        if is_installed "$pkg"; then
            echo -e "${GREEN}✅ $pkg уже установлен. Пропускаем.${NC}"
        else
            echo -e "${YELLOW}⬇️ Устанавливаем $pkg...${NC}"
            yay -S --needed --noconfirm "$pkg"
        fi
    done
}

# Установка nvm и Node.js с проверкой
install_nvm() {
    echo -e "${YELLOW}📌 Проверяем nvm и Node.js...${NC}"
    
    # Проверка nvm
    if ! command -v nvm &> /dev/null; then
        echo -e "${YELLOW}⬇️ Устанавливаем nvm...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        echo -e "${GREEN}✅ nvm уже установлен.${NC}"
    fi

    # Установка Node.js версий
    local node_versions=(16 21)
    for version in "${node_versions[@]}"; do
        if nvm ls "$version" &>/dev/null; then
            echo -e "${GREEN}✅ Node.js $version уже установлен.${NC}"
        else
            echo -e "${YELLOW}⬇️ Устанавливаем Node.js $version...${NC}"
            nvm install "$version"
        fi
    done

    # Установка ni
    echo -e "${YELLOW}⚡ Проверяем @antfu/ni...${NC}"
    nvm use 16
    if npm list -g | grep -q "@antfu/ni"; then
        echo -e "${GREEN}✅ @antfu/ni уже установлен для Node.js 16.${NC}"
    else
        echo -e "${YELLOW}⬇️ Устанавливаем @antfu/ni для Node.js 16...${NC}"
        npm i -g @antfu/ni
    fi

    nvm use 21
    if npm list -g | grep -q "@antfu/ni"; then
        echo -e "${GREEN}✅ @antfu/ni уже установлен для Node.js 21.${NC}"
    else
        echo -e "${YELLOW}⬇️ Устанавливаем @antfu/ni для Node.js 21...${NC}"
        npm i -g @antfu/ni
    fi
}

# Установка bun и ni с проверкой
install_bun() {
    echo -e "${YELLOW}🛠️ Проверяем bun...${NC}"
    
    if ! command -v bun &> /dev/null; then
        echo -e "${YELLOW}⬇️ Устанавливаем bun...${NC}"
        curl -fsSL https://bun.sh/install | bash
        export PATH="$HOME/.bun/bin:$PATH"
    else
        echo -e "${GREEN}✅ bun уже установлен.${NC}"
    fi

    echo -e "${YELLOW}🔍 Проверяем @antfu/ni в bun...${NC}"
    if bun pm ls | grep -q "@antfu/ni"; then
        echo -e "${GREEN}✅ @antfu/ni уже установлен в bun.${NC}"
    else
        echo -e "${YELLOW}⬇️ Устанавливаем @antfu/ni через bun...${NC}"
        bun i -g @antfu/ni
    fi
}

# Копирование конфигов Hyprland с бэкапом
copy_hypr_configs() {
    echo -e "${YELLOW}📂 Обновляем конфиги Hyprland...${NC}"
    HYPR_DIR="$HOME/.config/hypr"
    BACKUP_DIR="$HYPR_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$HYPR_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Функция для копирования с бэкапом
    copy_with_backup() {
        local file="$1"
        if [ -f "$file" ]; then
            if [ -f "$HYPR_DIR/$file" ]; then
                cp "$HYPR_DIR/$file" "$BACKUP_DIR/"
                echo -e "${GREEN}🔁 Создан бэкап: $BACKUP_DIR/$file${NC}"
            fi
            cp -f "$file" "$HYPR_DIR/"
            echo -e "${GREEN}✅ $file скопирован в $HYPR_DIR/${NC}"
        else
            echo -e "${RED}⚠️ Файл $file не найден в текущей директории!${NC}"
        fi
    }
    
    copy_with_backup "keybindings"
    copy_with_backup "windowrules"
}

# Основной процесс
main() {
    check_yay
    install_packages
    install_nvm
    install_bun
    copy_hypr_configs
    
    echo -e "\n${GREEN}🎉 Всё готово! Hyprland настроен под ваши требования.${NC}"
}

main "$@"
