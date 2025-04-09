#!/bin/bash

# ======================================================================
echo -e "\n\033[1;36m
   /\_/\           /\_/\
  ( o.o )         ( o.o ) 
   > ^ <           > ^ <
  _________________________________________________________
 /                                                         \
|   Привет! Я большой котик-инсталлятор Hyprland!           |
|   Сейчас магически настроим ваш Linux! (=｀ω´=)            |
 \_________________________________________________________/
    \  /         \  /
     \/           \/
\033[0m"
# ======================================================================

set -e  # Автоматически завершать скрипт при ошибке

# Цвета для удобства
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверяем, установлен ли yay
check_yay() {
    if ! command -v yay &> /dev/null; then
        echo -e "${RED}❌ yay не установлен! Установите его вручную:${NC}"
        echo "git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin && cd /tmp/yay-bin && makepkg -si --noconfirm"
        exit 1
    fi
}

# Установка пакетов через yay
install_packages() {
    echo -e "${YELLOW}🔄 Устанавливаем пакеты...${NC}"
    yay -S --needed --noconfirm \
        visual-studio-code-bin \
        zen-browser \
        telegram-desktop \
        spotify-launcher \
        ttf-maple-beta \
        nodejs
}

# Установка nvm и Node.js
install_nvm() {
    echo -e "${YELLOW}📌 Устанавливаем nvm и Node.js...${NC}"
    if ! command -v nvm &> /dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        nvm install 16
        nvm install 21
        nvm use 21
        
        # Устанавливаем ni для обеих версий Node
        echo -e "${YELLOW}⚡ Устанавливаем @antfu/ni для Node 16 и 21...${NC}"
        nvm use 16
        npm i -g @antfu/ni
        
        nvm use 21
        npm i -g @antfu/ni
    else
        echo -e "${GREEN}✅ nvm уже установлен. Пропускаем.${NC}"
    fi
}

# Установка bun и ni
install_bun() {
    echo -e "${YELLOW}🛠️ Устанавливаем bun и ni...${NC}"
    if ! command -v bun &> /dev/null; then
        curl -fsSL https://bun.sh/install | bash
        export PATH="$HOME/.bun/bin:$PATH"
    fi
    bun i -g @antfu/ni
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
