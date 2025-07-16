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

set -e

LOG_FILE="$HOME/hyprland_installer_$(date +%Y%m%d_%H%M%S).log"
exec 3>&1 1>"$LOG_FILE" 2>&1
trap 'echo "Логирование завершено. Полный лог: $LOG_FILE" >&3' EXIT

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${timestamp} - ${message}" | tee /dev/fd/3
}

TOTAL_STEPS=6
CURRENT_STEP=0
BAR_WIDTH=50

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

clear_status() {
    printf "\r%${COLUMNS}s\r" >&3
}

is_installed() {
    if pacman -Qi "$1" &>/dev/null || yay -Qi "$1" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

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

install_packages() {
    clear_status
    local packages=(
        zen-browser
        telegram-desktop
        spotify-launcher
        ttf-maplemono
        nodejs
    )
    local editor_pkg=""

    log "${YELLOW}🤔 Выбор редактора кода...${NC}"
    echo -e "\n${YELLOW}Какой редактор кода вы хотите установить?${NC}" >&3
    echo "  1) Visual Studio Code (стабильный и популярный)" >&3
    echo "  2) Zed Editor (быстрый, написан на Rust)" >&3

    local editor_choice
    while [[ "$editor_choice" != "1" && "$editor_choice" != "2" ]]; do
        read -r -p "Введите номер (1 или 2) и нажмите Enter: " editor_choice < /dev/tty

        case "$editor_choice" in
            1)
                editor_pkg="visual-studio-code-bin"
                log "   Выбран редактор: Visual Studio Code ($editor_pkg)"
                ;;
            2)
                editor_pkg="zed-editor"
                log "   Выбран редактор: Zed Editor ($editor_pkg)"
                ;;
            *)
                echo -e "${RED}Неверный выбор. Пожалуйста, введите 1 или 2.${NC}" >&3
                editor_choice=""
                ;;
        esac
    done

    packages+=("$editor_pkg")

    log "${YELLOW}📦 Начинаем установку выбранных пакетов...${NC}"

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

    export NVM_DIR="$HOME/.nvm" # Определяем NVM_DIR

    # Создаем директорию NVM_DIR, если она не существует
    # Это должно решить проблему "directory does not exist" из лога nvm install.sh
    if [ ! -d "$NVM_DIR" ]; then
        log "${YELLOW}   Создаем директорию для nvm: $NVM_DIR${NC}"
        if ! mkdir -p "$NVM_DIR"; then
            log "${RED}   ✗ Не удалось создать директорию $NVM_DIR${NC}"
            exit 1
        fi
    fi

    # Попытка загрузить nvm, если он уже установлен, но не загружен в текущей сессии
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh" # Загружаем nvm
    fi

    # Проверка nvm ПОСЛЕ попытки загрузки
    if ! command -v nvm &> /dev/null; then
        log "${YELLOW}   ↓ nvm не найден или не загружен. Устанавливаем nvm...${NC}"

        LATEST_NVM_TAG=$(curl -s "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

        if [ -z "$LATEST_NVM_TAG" ]; then
            log "${YELLOW}   ⚠️ Не удалось получить последнюю версию nvm, используем v0.39.7 как запасной вариант.${NC}"
            LATEST_NVM_TAG="v0.39.7" # Укажите здесь актуальную стабильную версию как fallback
        else
            log "   Используем последнюю версию nvm: $LATEST_NVM_TAG"
        fi

        # Установка nvm. Добавляем PROFILE=/dev/null чтобы nvm не пытался изменить .bashrc и т.п.
        # Мы сами загружаем nvm.sh
        # Переменная NVM_DIR уже экспортирована, и директория создана.
        if ! curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${LATEST_NVM_TAG}/install.sh" | PROFILE=/dev/null bash; then
            log "${RED}   ✗ Ошибка установки nvm${NC}"
            # Можно также проверить содержимое $NVM_DIR, если там появились какие-то логи от nvm
            exit 1 # Критическая ошибка, выходим
        fi

        # Загружаем nvm в текущую сессию оболочки ПОСЛЕ установки
        # Проверяем существование файла перед sourcing'ом
        if [ -s "$NVM_DIR/nvm.sh" ]; then
            . "$NVM_DIR/nvm.sh"
            log "${GREEN}   ✓ nvm установлен и загружен${NC}"
        else
            log "${RED}   ✗ Файл $NVM_DIR/nvm.sh не найден после установки nvm.${NC}"
            exit 1
        fi
    else
        log "${GREEN}   ✓ nvm уже установлен и загружен${NC}"
    fi

    # Дополнительная проверка, что nvm теперь точно доступен
    if ! command -v nvm &> /dev/null; then
        log "${RED}   ✗ FATAL: Команда nvm все еще недоступна после установки/загрузки. Проверьте ваш ~/.bashrc (или ~/.zshrc и т.д.) и перезапустите терминал, затем скрипт.${NC}"
        log "${RED}   ✗ Возможно, потребуется вручную добавить в ваш ~/.bashrc (или аналогичный):${NC}"
        log "${RED}   export NVM_DIR=\"\$HOME/.nvm\"${NC}"
        log "${RED}   [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\" # This loads nvm${NC}"
        log "${RED}   [ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"  # This loads nvm bash_completion${NC}"
        exit 1
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

        log "${YELLOW}   ⚡ Проверяем @antfu/ni для Node.js $version...${NC}"
        if ! nvm use "$version"; then
            log "${RED}   ✗ Не удалось переключиться на Node.js $version${NC}"
            continue
        fi

        if npm list -g --depth=0 @antfu/ni &>/dev/null; then
            log "${GREEN}   ✓ @antfu/ni уже установлен для Node.js $version${NC}"
        else
            log "${YELLOW}   ↓ Устанавливаем @antfu/ni для Node.js $version...${NC}"
            if ! npm i -g @antfu/ni; then
                log "${RED}   ✗ Ошибка установки @antfu/ni для Node.js $version${NC}"
            else
                log "${GREEN}   ✓ @antfu/ni установлен для Node.js $version${NC}"
            fi
        fi
    done

    if [ ${#node_versions[@]} -gt 0 ]; then
        latest_node_in_list="${node_versions[-1]}"
        if nvm alias default "$latest_node_in_list"; then
            log "${GREEN}   ✓ Node.js $latest_node_in_list установлен как версия по умолчанию.${NC}"
        else
            log "${YELLOW}   ⚠️ Не удалось установить Node.js $latest_node_in_list как версию по умолчанию.${NC}"
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
