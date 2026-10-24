#!/usr/bin/env bash

# ==============================================================================
# Ghostty Shader Switcher & Manager
# ==============================================================================
# Description : Manages, applies, chains, or clears custom GLSL shaders in
#               your Ghostty terminal configuration file.
# Compatibility: Linux (Arch, CachyOS, Ubuntu, etc.) & macOS
# ==============================================================================

# Strict mode: exit on error, undefined vars, or pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration & Constants
# ------------------------------------------------------------------------------
# Directory where shaders are located (defaults to current directory if not set)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHADERS_DIR="${GHOSTTY_SHADERS_DIR:-$SCRIPT_DIR}"

# Ghostty configuration file location
GHOSTTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
GHOSTTY_CONFIG="$GHOSTTY_CONFIG_DIR/config"

# Temporary file used for safe atomic updates
TMP_CONFIG="$GHOSTTY_CONFIG_DIR/config.tmp"

# Terminal styling output helpers
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# ------------------------------------------------------------------------------
# Helper Functions (UI & Logging)
# ------------------------------------------------------------------------------
log_info() {
    printf "${CYAN}[INFO]${RESET} %s\n" "$1"
}

log_success() {
    printf "${GREEN}[SUCCESS]${RESET} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${RESET} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${RESET} %s\n" "$1" >&2
}

# ------------------------------------------------------------------------------
# Validation & Pre-flight Checks
# ------------------------------------------------------------------------------

# Ensure Ghostty config directory and config file exist
ensure_ghostty_config() {
    if [[ ! -d "$GHOSTTY_CONFIG_DIR" ]]; then
        log_info "Creating Ghostty configuration directory at $GHOSTTY_CONFIG_DIR"
        mkdir -p "$GHOSTTY_CONFIG_DIR"
    fi

    if [[ ! -f "$GHOSTTY_CONFIG" ]]; then
        log_info "Creating empty Ghostty config at $GHOSTTY_CONFIG"
        touch "$GHOSTTY_CONFIG"
    fi
}

# Collect all available .glsl files in the target directory
get_available_shaders() {
    local shaders=()
    while IFS= read -r file; do
        [[ -f "$file" ]] && shaders+=("$file")
    done < <(find "$SHADERS_DIR" -maxdepth 2 -type f -name "*.glsl" | sort)

    if [[ ${#shaders[@]} -eq 0 ]]; then
        log_error "No .glsl shader files found in '$SHADERS_DIR'."
        exit 1
    fi

    printf "%s\n" "${shaders[@]}"
}

# ------------------------------------------------------------------------------
# Configuration Modification Logic
# ------------------------------------------------------------------------------

# Removes all existing 'custom-shader' directives from the Ghostty config
strip_existing_shaders() {
    grep -v '^[[:space:]]*custom-shader[[:space:]]*=' "$GHOSTTY_CONFIG" > "$TMP_CONFIG" || true
    mv "$TMP_CONFIG" "$GHOSTTY_CONFIG"
}

# Writes shader entries into the config file
# Usage: write_shaders_to_config ["/path/to/shader1.glsl" "/path/to/shader2.glsl"...]
write_shaders_to_config() {
    local shader_paths=("$@")

    # Create a backup before making structural changes
    cp "$GHOSTTY_CONFIG" "${GHOSTTY_CONFIG}.bak"

    # Strip old custom-shader entries
    strip_existing_shaders

    # Append new custom-shader entries
    {
        echo ""
        echo "# --- Ghostty Custom Shaders (Managed by shader.sh) ---"
        for shader in "${shader_paths[@]}"; do
            echo "custom-shader = $shader"
        done
    } >> "$GHOSTTY_CONFIG"

    # Enable shader animation if not already present
    if ! grep -q '^[[:space:]]*custom-shader-animation' "$GHOSTTY_CONFIG"; then
        echo "custom-shader-animation = true" >> "$GHOSTTY_CONFIG"
    fi

    log_success "Updated $GHOSTTY_CONFIG successfully!"
    log_info "Active Shaders:"
    for shader in "${shader_paths[@]}"; do
        printf "  • %s\n" "$(basename "$shader")"
    done
    
    log_info "Reload Ghostty configuration with (Cmd+Shift+,) or (Ctrl+Shift+,) to apply."
}

# Clear all custom shaders from the Ghostty configuration
clear_shaders() {
    strip_existing_shaders
    log_success "Cleared all custom shader entries from $GHOSTTY_CONFIG."
}

# ------------------------------------------------------------------------------
# Interactive Selection Modes
# ------------------------------------------------------------------------------

# Interactive picker using fzf (supports multi-selection with Tab)
select_via_fzf() {
    local selected_files
    mapfile -t selected_files < <(
        get_available_shaders | fzf --multi \
            --prompt="Select Shader(s) > " \
            --header="TAB: Multi-select | ENTER: Confirm | CTRL-A: Select All" \
            --preview='head -n 20 {}' \
            --height=60% --border
    )

    if [[ ${#selected_files[@]} -eq 0 ]]; then
        log_warn "No shader selected. Exiting."
        exit 0
    fi

    write_shaders_to_config "${selected_files[@]}"
}

# Fallback interactive picker using basic bash select prompt
select_via_menu() {
    mapfile -t shaders < <(get_available_shaders)
    
    echo -e "${BOLD}Available Shaders:${RESET}"
    PS3="Select a shader number (or q to quit): "
    
    select choice in "${shaders[@]}"; do
        if [[ "$REPLY" == "q" ]]; then
            log_info "Operation canceled."
            exit 0
        elif [[ -n "$choice" ]]; then
            write_shaders_to_config "$choice"
            break
        else
            log_warn "Invalid selection."
        fi
    done
}

# List all current shaders set in the config file
list_active_shaders() {
    if grep -q '^[[:space:]]*custom-shader[[:space:]]*=' "$GHOSTTY_CONFIG"; then
        echo -e "${BOLD}Currently configured Ghostty Shaders:${RESET}"
        grep '^[[:space:]]*custom-shader[[:space:]]*=' "$GHOSTTY_CONFIG" | awk -F'=' '{print "  • " $2}'
    else
        log_info "No custom shaders currently active in $GHOSTTY_CONFIG"
    fi
}

# Print help / usage banner
show_help() {
    cat << EOF
Ghostty Shader Manager

Usage:
  ./shader.sh [OPTION] [SHADER_NAME_OR_PATH]

Options:
  -i, --interactive    Interactively select shader using fzf (or select menu).
  -l, --list           Display currently configured shaders in Ghostty.
  -c, --clear          Disable/Remove all custom shaders from Ghostty config.
  -a, --add <shader>   Append a shader to the current chain without replacing existing ones.
  -s, --set <shader>   Set a specific shader file (replaces current shaders).
  -h, --help           Show this help message.

Examples:
  ./shader.sh                          # Opens interactive picker
  ./shader.sh --set matrix.glsl        # Replaces config with matrix.glsl
  ./shader.sh --add bloom.glsl         # Chains bloom.glsl on top of current shaders
  ./shader.sh --clear                  # Disables shaders
EOF
}

# ------------------------------------------------------------------------------
# Main Execution Entry Point
# ------------------------------------------------------------------------------
main() {
    ensure_ghostty_config

    if [[ $# -eq 0 ]]; then
        if command -v fzf &>/dev/null; then
            select_via_fzf
        else
            log_warn "'fzf' is not installed. Falling back to simple menu."
            select_via_menu
        fi
        exit 0
    fi

    case "$1" in
        -i|--interactive)
            if command -v fzf &>/dev/null; then
                select_via_fzf
            else
                select_via_menu
            fi
            ;;
        -l|--list)
            list_active_shaders
            ;;
        -c|--clear)
            clear_shaders
            ;;
        -s|--set)
            shift
            if [[ $# -eq 0 ]]; then
                log_error "Please specify a shader file."
                exit 1
            fi
            local target="$1"
            [[ ! -f "$target" ]] && target="$SHADERS_DIR/$1"
            if [[ -f "$target" ]]; then
                write_shaders_to_config "$target"
            else
                log_error "Shader file '$1' not found."
                exit 1
            fi
            ;;
        -a|--add)
            shift
            if [[ $# -eq 0 ]]; then
                log_error "Please specify a shader file to add."
                exit 1
            fi
            local target="$1"
            [[ ! -f "$target" ]] && target="$SHADERS_DIR/$1"
            if [[ -f "$target" ]]; then
                # Get existing shaders and add new one
                mapfile -t current < <(grep '^[[:space:]]*custom-shader[[:space:]]*=' "$GHOSTTY_CONFIG" | awk -F'=' '{print $2}' | xargs)
                current+=("$target")
                write_shaders_to_config "${current[@]}"
            else
                log_error "Shader file '$1' not found."
                exit 1
            fi
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"