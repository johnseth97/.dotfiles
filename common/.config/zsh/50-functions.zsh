# Interactive functions.

# Clipboard front ends to the standalone POSIX pg.sh utility. Capture first:
# the recipient picker may ask you to replace the clipboard with a public key.
_pgclipboard() {
  local option
  for option in "$@"; do
    if [[ $option == --help || $option == -h ]]; then
      command "$HOME/.bin/pg.sh" --help
      return $?
    fi
  done
  if (( ! $+aliases[paste] && ! $+functions[paste] )); then
    print -u2 -- 'pg: define a clipboard paste alias/function first.'
    return 127
  fi
  local message_file backend function_source
  message_file=$(mktemp "${TMPDIR:-/tmp}/pg-clipboard.XXXXXXXX") || return 1
  if [[ -n ${PG_CLIPBOARD_COMMAND:-} ]]; then
    backend=$PG_CLIPBOARD_COMMAND
  elif (( $+aliases[paste] )); then
    # Run trusted shell configuration in Zsh, so complex aliases still work.
    backend="zsh -fc ${(q)aliases[paste]}"
  else
    function_source="$(functions paste)"$'\n''paste'
    backend="zsh -fc ${(q)function_source}"
  fi
  {
    eval 'paste' > "$message_file" || {
      print -u2 -- 'pg: clipboard read failed.'
      return 1
    }
    PG_CLIPBOARD_COMMAND=$backend command "$HOME/.bin/pg.sh" "$@" --file "$message_file"
  } always {
    command rm -f -- "$message_file"
  }
}

pgpaste() { _pgclipboard --auto "$@"; }
pgsign() { _pgclipboard --sign "$@"; }
pgencrypt() {
  if (( $# )) && [[ $1 != -* ]]; then
    local recipient=$1
    shift
    _pgclipboard --encrypt --recipient "$recipient" "$@"
  else
    _pgclipboard --encrypt "$@"
  fi
}
pghide() { pgencrypt "$@"; }
pgopen() { _pgclipboard --decrypt "$@"; }

# Export first, then copy only on success: failed selection leaves clipboard intact.
pgcopy() {
  local option public_file
  for option in "$@"; do
    if [[ $option == --help || $option == -h ]]; then
      command "$HOME/.bin/pg.sh" --help
      return $?
    fi
  done
  local expect_key=false
  for option in "$@"; do
    if $expect_key; then
      expect_key=false
      continue
    fi
    case $option in
      --key) expect_key=true ;;
      --verbose|-v) ;;
      *) print -u2 -- 'Usage: pgcopy [--key ID] [--verbose]'; return 2 ;;
    esac
  done
  if $expect_key; then
    print -u2 -- 'pgcopy: --key needs an identity.'
    return 2
  fi
  public_file=$(mktemp "${TMPDIR:-/tmp}/pg-public.XXXXXXXX") || return 1
  {
    command "$HOME/.bin/pg.sh" --export-public "$@" > "$public_file" || return $?
    if [[ -n ${PG_COPY_COMMAND:-} ]]; then
      command sh -c "$PG_COPY_COMMAND" < "$public_file" || return $?
    elif (( $+aliases[copy] || $+functions[copy] )); then
      eval 'copy' < "$public_file" || return $?
    elif [[ $OSTYPE == darwin* ]] && (( $+commands[pbcopy] )); then
      command pbcopy < "$public_file" || return $?
    elif [[ -n ${WAYLAND_DISPLAY:-} ]] && (( $+commands[wl-copy] )); then
      command wl-copy < "$public_file" || return $?
    elif (( $+commands[xclip] )); then
      command xclip -selection clipboard -i < "$public_file" || return $?
    elif (( $+commands[xsel] )); then
      command xsel --clipboard --input < "$public_file" || return $?
    else
      print -u2 -- 'pgcopy: configure copy/PG_COPY_COMMAND or install a clipboard writer.'
      return 127
    fi
    print -u2 -- 'pgcopy: public certificate copied. Share it; keep private keys private.'
  } always {
    command rm -f -- "$public_file"
  }
}

ghostty-setup() {
  local host=${1:?usage: ghostty-setup user@host}
  infocmp -x | ssh "$host" -- tic -x -
}

# Send an OSC 9 desktop notification to the terminal host. In tmux, prefer the
# attached client's TTY so the sequence reaches Ghostty directly.
_osc9-send() {
  local message=${*:-Notification}
  local target_tty=/dev/tty
  local use_tmux_passthrough=false

  # OSC strings cannot safely contain terminators or separators supplied by a
  # caller. Keep this a one-line terminal notification, not a control channel.
  message=${message//$'\e'/ }
  message=${message//$'\a'/ }
  message=${message//$'\r'/ }
  message=${message//$'\n'/ }
  message=${message//;/,}

  if [[ -n ${TMUX:-} && -n ${commands[tmux]:-} ]]; then
    local client_tty
    client_tty=$(command tmux display-message -p '#{client_tty}' 2>/dev/null)
    if [[ -n $client_tty && -w $client_tty ]]; then
      target_tty=$client_tty
    else
      use_tmux_passthrough=true
    fi
  fi

  if [[ ! -w $target_tty ]]; then
    print -u2 -- "osc9-notify: cannot write to ${target_tty}"
    return 1
  fi

  if $use_tmux_passthrough; then
    # Fallback for a detached tmux client; requires allow-passthrough on.
    printf '\ePtmux;\e\e]9;%s\e\\\e\\' "$message" >"$target_tty"
  else
    printf '\e]9;%s\e\\' "$message" >"$target_tty"
  fi
}

# Send a message, or run a command and notify when it finishes.
#
#   osc9-notify "The deploy is ready"
#   osc9-notify -- make test
#   osc9-notify --result -- ./long-task --verbose
osc9-notify() {
  local include_result=false

  case ${1:-} in
    --help|-h)
      cat <<'EOF'
Usage:
  notify-host MESSAGE
  notify-host -- COMMAND [ARGUMENT ...]
  notify-host --result -- COMMAND [ARGUMENT ...]

Run a command and notify with its exit status and elapsed time. `--result`
also includes a short tail of the command's combined output.
EOF
      return
      ;;
    --result)
      include_result=true
      shift
      ;;
  esac

  if [[ ${1:-} != '--' ]]; then
    if [[ $include_result == true ]]; then
      print -u2 -- 'osc9-notify: --result requires -- COMMAND'
      return 2
    fi
    _osc9-send "$*"
    return
  fi
  shift

  if (( $# == 0 )); then
    print -u2 -- 'osc9-notify: expected a command after --'
    return 2
  fi

  local command_line=''
  local argument
  for argument in "$@"; do
    command_line+="${(q)argument} "
  done
  command_line=${command_line% }

  zmodload zsh/datetime 2>/dev/null
  local started_at=$EPOCHREALTIME
  local exit_status result=''

  if [[ $include_result == true ]]; then
    local result_file
    result_file=$(mktemp "${TMPDIR:-/tmp}/osc9-notify.XXXXXX") || return 1
    setopt localoptions pipefail
    "$@" 2>&1 | tee "$result_file"
    exit_status=${pipestatus[1]}
    result=$(<"$result_file")
    command rm -f -- "$result_file"
  else
    "$@"
    exit_status=$?
  fi

  local elapsed=$(( EPOCHREALTIME - started_at ))
  local duration
  duration=$(printf '%.1fs' "$elapsed")

  local summary
  if (( exit_status == 0 )); then
    summary="✓ ${command_line} completed in ${duration}"
  else
    summary="✗ ${command_line} failed (exit ${exit_status}) after ${duration}"
  fi

  if [[ -n $result ]]; then
    result=${result//$'\r'/ }
    result=${result//$'\n'/ }
    result=${result## ##}
    result=${result%% ##}
    if (( ${#result} > 180 )); then
      result="…${result[-179,-1]}"
    fi
    summary+=" — ${result}"
  fi

  _osc9-send "$summary"
  return "$exit_status"
}

dots() {
  local action=${1:-help}
  shift $(( $# > 0 ? 1 : 0 ))

  case "$action" in
    plan) command dotfiles-stow --dry-run --restow "$@" ;;
    deploy) command dotfiles-stow --restow "$@" ;;
    sync) command sync-dotfiles "$@" ;;
    bootstrap) command bootstrap "$@" ;;
    shell-update)
      if (( $+commands[brew] )); then
        command brew upgrade antidote
      fi
      (( $+functions[antidote] )) || {
        print -u2 -- '[dots] Antidote is not loaded.'
        return 1
      }
      antidote update --bundles "$@"
      ;;
    status)
      command git -C "$HOME/.dotfiles" status --short
      ;;
    help|-h|--help)
      cat <<'EOF'
Usage: dots <action> [arguments]

  plan          preview a restow without changing $HOME
  deploy        restow packages for this platform
  sync          fast-forward dotfiles and pinned submodules, then restow,
                then sync any optional companion repo already cloned locally
  bootstrap     install dependencies and deploy a new host
  shell-update  update Homebrew Antidote, then declared Antidote plugins
  status        show dotfiles worktree state
EOF
      ;;
    *)
      print -u2 -- "[dots] unknown action: $action"
      return 2
      ;;
  esac
}

_dots() {
  local action=${words[2]:-}
  local -a actions
  actions=(
    'plan:preview a restow without changing HOME'
    'deploy:restow packages for this platform'
    'sync:update the root repo and pinned submodules, restow, then sync optional companion repos'
    'bootstrap:prepare a new host, cloning missing optional companion repos'
    'shell-update:update packaged Antidote and declared plugin bundles'
    'status:show dotfiles worktree state'
  )

  if (( CURRENT == 2 )); then
    _describe -t actions 'dots action' actions
    return
  fi

  case "$action" in
    plan|deploy)
      _arguments -S \
        '--platform=[target platform]:platform:(auto macos linux wsl)' \
        '--dry-run[show the Stow operation without changing HOME]' \
        '--restow[restow the selected packages]'
      ;;
    bootstrap)
      _arguments -S \
        '--platform=[target platform]:platform:(auto macos linux wsl)' \
        '--dry-run[show work without changing the host]' \
        '--skip-packages[do not install system dependencies]' \
        '--skip-tmux-plugins[defer TPM plugin installation]' \
        '--skip-optional-repos[do not clone optional companion repos]'
      ;;
    shell-update)
      _arguments -S \
        '(-b --bundles)'{-b,--bundles}'[update bundles only]' \
        '(-n --dry-run)'{-n,--dry-run}'[show bundle updates without applying them]'
      ;;
    sync)
      _arguments -S \
        '--check[report local drift, no network]'
      ;;
    status)
      _message 'this action accepts no options'
      ;;
  esac
}

compdef _dots dots
