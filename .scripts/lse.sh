#!/bin/zsh

lse() {
    if [[ -z "$1" ]]; then
        echo "Usage: lse <filename>"
        return 1
    fi

    if [[ ! -e "$1" ]]; then
        echo "Error: File '$1' does not exist."
        return 1
    fi

    echo "📂 File: $1"
    echo "---------------------------"
    echo "📜 Type: $(file -b "$1")"
    echo "🔐 Permissions: $(stat -c "%A (%a)" "$1")"
    echo "👤 Owner: $(stat -c "%U" "$1")"
    echo "📅 Last Modified: $(stat -c "%y" "$1")"
    echo "⚡ Attributes: $(lsattr "$1" 2>/dev/null || echo "No special attributes")"
}


