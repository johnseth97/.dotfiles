#!/bin/zsh

echo "🔍 Running Spotlight diagnostics and benchmark..."

function time_mdfind() {
    echo "\n🕐 Testing: $1"
    time mdfind "$1" | wc -l
}

# Test general indexing health
echo "\n📁 Total indexed files (user domain):"
mdfind -onlyin ~ '*' | wc -l

echo "\n📁 Total indexed files (root volume):"
mdfind -onlyin / '*' | wc -l

# Test real queries
time_mdfind "kMDItemKind == 'PDF'"
time_mdfind "kMDItemFSName == '*.md'"
time_mdfind "kMDItemWhereFroms == '*'"
time_mdfind "kMDItemContentType == 'public.plain-text'"
time_mdfind "kMDItemTextContent == 'Spotlight'"

# Check for stuck/damaged index stores
echo "\n🧼 Orphaned or stale index folders:"
sudo find / -type d -name '.Spotlight-V100' 2>/dev/null

echo "\n✅ Done. If all queries return results quickly and file counts seem reasonable, Spotlight is probably fine."
