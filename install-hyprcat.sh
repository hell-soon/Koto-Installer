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

# Настройка логирования
LOG_FILE="$HOME/hyprland_installer_$(date +%Y%m%d_%H%M%S).log"
exec 3>&1 1>"$LOG_FILE" 2>&1
trap 'echo "Логирование завершено. Полный лог: $LOG_FILE" >&3' EXIT

# Цвета для удобства
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода в консоль и лог
log() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${timestamp} - ${message}" | tee /dev/fd/3
}

# Переменные для прогресс-бара
TOTAL_STEPS=6
CURRENT_STEP=0
BAR_WIDTH=50

# Функция для отображения прогресса
show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    FILL=$((CURRENT_STEP * BAR_WIDTH / TOTAL_STEPS))
    EMPTY=$((BAR_WIDTH - FILL))
    
    printf "\r${BLUE}Прогресс: ["
    printf "%${FILL}s" | tr ' ' '='
    printf "%${EMPTY}s" | tr ' ' ' '
    printf "] %d%%${NC}" $PERCENT >&3
}

# Функция для очистки строки состояния
clear_status() {
    printf "\r%${COLUMNS}s\r" >&3
}

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
    clear_status
    log "${YELLOW}🔍 Проверяем наличие yay...${NC}"
    
    if ! command -v yay &> /dev/null; then
        log "${RED}❌ yay не установлен! Установите его вручную:${NC}"
        log "git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin && cd /tmp/yay-bin && makepkg -si --noconfirm"
        exit 1
    fi
    show_progress
    log "${GREEN}✅ yay установлен.${NC}"
}

# Установка пакетов через yay с проверкой
install_packages() {
    clear_status
    local packages=(
        visual-studio-code-bin
        zen-browser
        telegram-desktop
        spotify-launcher
        ttf-maplemono
        nodejs
    )

    log "${YELLOW}📦 Начинаем установку пакетов...${NC}"
    
    for pkg in "${packages[@]}"; do
        if is_installed "$pkg"; then
            log "${GREEN}   ✓ $pkg уже установлен${NC}"
        else
            log "${YELLOW}   ↓ Устанавливаем $pkg...${NC}"
            if ! yay -S --needed --noconfirm "$pkg"; then
                log "${RED}   ✗ Ошибка установки $pkg${NC}"
                continue
            fi
            log "${GREEN}   ✓ $pkg успешно установлен${NC}"
        fi
    done
    
    show_progress
}

# Установка nvm и Node.js с проверкой
install_nvm() {
    clear_status
    log "${YELLOW}🔄 Настраиваем nvm и Node.js...${NC}"
    
    # Проверка nvm
    if ! command -v nvm &> /dev/null; then
        log "${YELLOW}   ↓ Устанавливаем nvm...${NC}"
        if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash; then
            log "${RED}   ✗ Ошибка установки nvm${NC}"
            exit 1
        fi
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        log "${GREEN}   ✓ nvm установлен${NC}"
    else
        log "${GREEN}   ✓ nvm уже установлен${NC}"
    fi

    # Установка Node.js версий
    local node_versions=(16 21)
    for version in "${node_versions[@]}"; do
        if nvm ls "$version" &>/dev/null; then
            log "${GREEN}   ✓ Node.js $version уже установлен${NC}"
        else
            log "${YELLOW}   ↓ Устанавливаем Node.js $version...${NC}"
            if ! nvm install "$version"; then
                log "${RED}   ✗ Ошибка установки Node.js $version${NC}"
                continue
            fi
            log "${GREEN}   ✓ Node.js $version установлен${NC}"
        fi
    done

    # Установка ni
    log "${YELLOW}   ⚡ Проверяем @antfu/ni...${NC}"
    if ! nvm use 16; then
        log "${RED}   ✗ Не удалось переключиться на Node.js 16${NC}"
    else
        if npm list -g | grep -q "@antfu/ni"; then
            log "${GREEN}   ✓ @antfu/ni уже установлен для Node.js 16${NC}"
        else
            log "${YELLOW}   ↓ Устанавливаем @antfu/ni для Node.js 16...${NC}"
            if ! npm i -g @antfu/ni; then
                log "${RED}   ✗ Ошибка установки @antfu/ni для Node.js 16${NC}"
            else
                log "${GREEN}   ✓ @antfu/ni установлен для Node.js 16${NC}"
            fi
        fi
    fi

    if ! nvm use 21; then
        log "${RED}   ✗ Не удалось переключиться на Node.js 21${NC}"
    else
        if npm list -g | grep -q "@antfu/ni"; then
            log "${GREEN}   ✓ @antfu/ni уже установлен для Node.js 21${NC}"
        else
            log "${YELLOW}   ↓ Устанавливаем @antfu/ni для Node.js 21...${NC}"
            if ! npm i -g @antfu/ni; then
                log "${RED}   ✗ Ошибка установки @antfu/ni для Node.js 21${NC}"
            else
                log "${GREEN}   ✓ @antfu/ni установлен для Node.js 21${NC}"
            fi
        fi
    fi
    
    show_progress
}

# Установка bun и ni с проверкой
install_bun() {
    clear_status
    log "${YELLOW}🐇 Настраиваем bun...${NC}"
    
    if ! command -v bun &> /dev/null; then
        log "${YELLOW}   ↓ Устанавливаем bun...${NC}"
        if ! curl -fsSL https://bun.sh/install | bash; then
            log "${RED}   ✗ Ошибка установки bun${NC}"
            exit 1
        fi
        export PATH="$HOME/.bun/bin:$PATH"
        log "${GREEN}   ✓ bun установлен${NC}"
    else
        log "${GREEN}   ✓ bun уже установлен${NC}"
    fi

    log "${YELLOW}   🔍 Проверяем @antfu/ni в bun...${NC}"
    if bun pm ls | grep -q "@antfu/ni"; then
        log "${GREEN}   ✓ @antfu/ni уже установлен в bun${NC}"
    else
        log "${YELLOW}   ↓ Устанавливаем @antfu/ni через bun...${NC}"
        if ! bun i -g @antfu/ni; then
            log "${RED}   ✗ Ошибка установки @antfu/ni через bun${NC}"
        else
            log "${GREEN}   ✓ @antfu/ni установлен в bun${NC}"
        fi
    fi
    
    show_progress
}

# Копирование конфигов Hyprland с бэкапом
copy_hypr_configs() {
    clear_status
    log "${YELLOW}📂 Обновляем конфиги Hyprland...${NC}"
    HYPR_DIR="$HOME/.config/hypr"
    BACKUP_DIR="$HYPR_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$HYPR_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Функция для копирования с бэкапом
    copy_with_backup() {
        local file="$1"
        if [ -f "$file" ]; then
            if [ -f "$HYPR_DIR/$file" ]; then
                if ! cp "$HYPR_DIR/$file" "$BACKUP_DIR/"; then
                    log "${RED}   ✗ Ошибка создания бэкапа $file${NC}"
                    return
                fi
                log "${GREEN}   🔄 Создан бэкап $file${NC}"
            fi
            if ! cp -f "$file" "$HYPR_DIR/"; then
                log "${RED}   ✗ Ошибка копирования $file${NC}"
                return
            fi
            log "${GREEN}   ✓ $file скопирован${NC}"
        else
            log "${RED}   ⚠️ Файл $file не найден!${NC}"
        fi
    }
    
    copy_with_backup "keybindings.conf"
    copy_with_backup "windowrules.conf"
    
    show_progress
}

# Основной процесс
main() {
    log "${BLUE}🐱 Начало работы котик-инсталлятора 🐱${NC}"
    log "Логирование в файл: $LOG_FILE"
    
    check_yay
    install_packages
    install_nvm
    install_bun
    copy_hypr_configs
    
    clear_status
    log "\n${GREEN}🎉 Всё готово! Hyprland настроен под ваши требования.${NC}"
    log "${BLUE}🐱 Спасибо за использование котик-инсталлятора! =^..^=${NC}"
    log "Полный лог установки: $LOG_FILE"
    
    # Выводим финальное сообщение в консоль
    echo -e "\n${GREEN}🎉 Всё готово! Hyprland настроен под ваши требования.${NC}" >&3
    echo -e "${BLUE}🐱 Спасибо за использование котик-инсталлятора! =^..^=${NC}" >&3
    echo -e "Полный лог установки: $LOG_FILE" >&3
}

main "$@"
