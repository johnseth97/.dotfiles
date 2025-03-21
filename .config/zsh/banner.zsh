#!/bin/zsh

# Colors
RED=$'\033[31m'       # Red
GREEN=$'\033[32m'     # Green
YELLOW=$'\033[33m'    # Yellow
BLUE=$'\033[34m'      # Blue
MAGENTA=$'\033[35m'   # Magenta
CYAN=$'\033[36m'      # Cyan
RESET=$'\033[0m'      # Reset color

# Gather information
HOSTNAME=$(hostname)
IP=$(ipconfig getifaddr en0 2>/dev/null || echo "N/A")
TIME=$(date "+%H:%M:%S")
SYSTEM=$(uname -sm)
ALIASES=$(alias | wc -l | awk '{print $1}')
PLUGINS=${#plugins[@]:-0}
BANNER_TERMINFO=${TERMINFO_DIRS:-$TERMINFO}


# Check if profiling is enabled
if [[ "$ZSH_PROFILE_STARTUP" == "1" ]]; then
    PROFILER_DATA=$(zmodload zsh/zprof; zprof)

    # Ensure profiler output file exists
    PROFILER_FILE="$HOME/.zsh_profiler_data.txt"
    : > "$PROFILER_FILE"  # Truncate or create the file safely

    # Write profiler data to the file
    if [[ -n "$PROFILER_DATA" ]]; then
        echo "$PROFILER_DATA" > "$PROFILER_FILE"
    else
        echo "No profiler data available." > "$PROFILER_FILE"
    fi	

    # Initialize sums
    TOTAL_TIME=0
    TOTAL_SELF_TIME=0

    # Process zprof output
    if [[ -n "$PROFILER_DATA" ]]; then
        while IFS= read -r line; do
            if echo "$line" | grep -Eq '^[[:space:]]*[0-9]+\)'; then
                TIME=$(echo "$line" | awk '{print $3}')
                SELF_TIME=$(echo "$line" | awk '{print $6}')
                if [[ "$TIME" =~ ^[0-9.]+$ ]] && [[ "$SELF_TIME" =~ ^[0-9.]+$ ]]; then
                    TOTAL_TIME=$(awk "BEGIN {print $TOTAL_TIME + $TIME}")
                    TOTAL_SELF_TIME=$(awk "BEGIN {print $TOTAL_SELF_TIME + $SELF_TIME}")
                fi
            fi
        done <<< "$PROFILER_DATA"

        # Format totals
        TOTAL_TIME=$(printf "%.2fms" "$TOTAL_TIME")
        TOTAL_SELF_TIME=$(printf "%.2fms" "$TOTAL_SELF_TIME")
        PROFILER_SUMMARY="  spent: $TOTAL_TIME\n  self-time: $TOTAL_SELF_TIME"
    else
        PROFILER_SUMMARY="No profiler data available."
    fi
fi

# Print banner
print -P "\n${CYAN}System:${GREEN} ${SYSTEM}${RESET}"
print -P "${CYAN}Hostname:${YELLOW} ${HOSTNAME}${RESET}"
print -P "${CYAN}IP Address:${BLUE} ${IP}${RESET}"
print -P "${CYAN}Terminfo:${MAGENTA} ${BANNER_TERMINFO}${RESET}"
print -P "${CYAN}Loaded Plugins:${RED} ${PLUGINS}${RESET}"
print -P "${CYAN}Aliases:${RED} ${ALIASES}${RESET}"
print -P "${CYAN}Time:${YELLOW} ${TIME}${RESET}"

# Print profiler summary if zprof is enabled
if [[ "$ZSH_PROFILE_STARTUP" == "1" ]]; then
    print -P "\n${CYAN}Profiler Summary:${RESET}"
    print -P "${YELLOW}${PROFILER_SUMMARY}${RESET}\n"
fi
