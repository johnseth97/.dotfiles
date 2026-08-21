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

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS uses BSD stat
        perms=$(stat -f "%Sp (%Lp)" "$1")
        owner=$(stat -f "%Su" "$1")
        modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$1")
    else
        # Linux uses GNU stat
        perms=$(stat -c "%A (%a)" "$1")
        owner=$(stat -c "%U" "$1")
        modified=$(stat -c "%y" "$1")
    fi

    echo "🔐 Permissions: $perms"
    echo "👤 Owner: $owner"
    echo "📅 Last Modified: $modified"
    echo "⚡ Attributes: $(lsattr "$1" 2>/dev/null || echo "No special attributes")"
}
