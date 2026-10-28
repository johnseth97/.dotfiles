# Optional local toolchains.

export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk"
export PATH="$HOME/zephyr-sdk/arm-zephyr-eabi/bin:$PATH"

export CARGO_ROOT="$HOME/.cargo/bin/"
export PATH="$CARGO_ROOT:$PATH"

# Fedora's `golang` package bakes GOTOOLCHAIN=local and GOSUMDB=off into the
# binary (not into a go env file, so `go env` shows them with no visible
# source). Together they make `go install` fail on any module needing a newer
# Go than the packaged one: it refuses to fetch the toolchain, and with the
# checksum DB off it cannot verify golang.org/toolchain even when asked to.
# Both are Fedora's offline-build defaults, not security hardening -- GOSUMDB
# off means no verification at all. Restore upstream Go's behaviour. No-ops on
# macOS, where Homebrew's go already ships these values.
export GOTOOLCHAIN=auto
export GOSUMDB=sum.golang.org

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi
