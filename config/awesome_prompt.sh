#!/bin/bash

# Awesome Bash Prompt Configuration
# Features:
# - Python virtual environment detection
# - Git branch and status
# - System information
# - Last command exit status
# - Current time
# - Directory path with truncation
# - Color coding for different states

# Colors (PS1에서만 사용)
RED="\[\033[0;31m\]"
GREEN="\[\033[0;32m\]"
YELLOW="\[\033[1;33m\]"
BLUE="\[\033[0;34m\]"
PURPLE="\[\033[0;35m\]"
CYAN="\[\033[0;36m\]"
WHITE="\[\033[1;37m\]"
GRAY="\[\033[0;37m\]"
RESET="\[\033[0m\]"

# Function to get Python virtual environment (색상 없이)
get_python_env() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local env_name=$(basename "$VIRTUAL_ENV")
        echo -n "🐍(${env_name}) "
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        echo -n "🐍(${CONDA_DEFAULT_ENV}) "
    fi
}

# Function to get Git information (색상 없이)
get_git_info() {
    local git_branch=$(git branch 2>/dev/null | sed -n '/\* /s///p')
    if [[ -n "$git_branch" ]]; then
        local git_status=$(git status --porcelain 2>/dev/null)
        local status_symbol="●"
        local status="clean"
        if [[ -n "$git_status" ]]; then
            status="dirty"
        fi
        echo -n "git:(${git_branch})${status_symbol} ${status} "
    fi
}

# Function to get system information (색상 없이)
get_system_info() {
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo -n "[L:${load_avg} M:${mem_usage}% D:${disk_usage}%] "
}

# Function to get current time (색상 없이)
get_time() {
    echo -n "$(date '+%H:%M:%S') "
}

# Function to get exit status (색상 없이)
get_exit_status() {
    if [[ $? -eq 0 ]]; then
        echo -n "✓ "
    else
        echo -n "✗ "
    fi
}

# Function to get current directory (truncated if too long, 색상 없이)
get_current_dir() {
    local pwd_length=${#PWD}
    local max_length=50
    if [[ $pwd_length -gt $max_length ]]; then
        echo -n "...${PWD: -$((max_length-3))}"
    else
        echo -n "$PWD"
    fi
}

# Main prompt function
set_awesome_prompt() {
    if [[ $EUID -eq 0 ]]; then
        local user_color="$RED"
    else
        local user_color="$GREEN"
    fi
    PS1=""
    PS1+="${PURPLE}\$(get_python_env)${RESET} "
    PS1+="${CYAN}\$(get_current_dir)${RESET}"
    PS1+="\$(git branch 2>/dev/null | grep -q '*' && (git status --porcelain 2>/dev/null | grep -q . && echo '${YELLOW}' || echo '${BLUE}'))"
    PS1+="${GREEN}\$(get_exit_status)${RESET} "
    PS1+="${GRAY}\$(get_time)\$(get_system_info)${RESET} "
    # Git 상태에 따라 색상 분기
    PS1+="\$(get_git_info)${RESET} "
    PS1+="${user_color}\u@\h${RESET}:"
    PS1+="\n${YELLOW}\$${RESET} "
}

set_awesome_prompt
export -f set_awesome_prompt 