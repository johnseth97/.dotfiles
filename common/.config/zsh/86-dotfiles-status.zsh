# Report dotfiles / optional-companion-repo sync drift at shell start,
# mirroring brew-watchtower's blurb: silent if everything is in sync, one
# line per repo that has something to report. sync-dotfiles --check is
# local-only (no network fetch), so this adds no startup latency.

if [[ $- == *i* && -t 1 ]]; then
  command -v sync-dotfiles >/dev/null 2>&1 && sync-dotfiles --check
fi
