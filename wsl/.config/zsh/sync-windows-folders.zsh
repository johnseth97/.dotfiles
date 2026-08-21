# Link Windows folders into the WSL home without embedding a Windows username
# or organization name. Prefer Windows' account metadata, then accept only an
# unambiguous filesystem match.
setup_wsl_windows_folder_links() {
  local windows_home windows_path onedrive_root link_path target_path current_target
  local -a candidates

  windows_home="${WINHOME:-$(cmd.exe /D /C 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r' | wslpath -u 2>/dev/null)}"
  windows_path=$(cmd.exe /D /C 'echo %OneDriveCommercial%' 2>/dev/null | tr -d '\r')
  if [[ -n "$windows_path" && "$windows_path" != '%OneDriveCommercial%' ]]; then
    onedrive_root=$(printf '%s' "$windows_path" | wslpath -u 2>/dev/null)
  fi

  if [[ ! -d "$onedrive_root" ]] && (( $+commands[powershell.exe] )); then
    windows_path=$(powershell.exe -NoLogo -NoProfile -NonInteractive -Command \
      '$folders = @(Get-ItemProperty "HKCU:\Software\Microsoft\OneDrive\Accounts\Business*" -Name UserFolder -ErrorAction SilentlyContinue | ForEach-Object UserFolder); if ($folders.Count -eq 1) { $folders[0] }' \
      2>/dev/null | tr -d '\r')
    [[ -n "$windows_path" ]] && onedrive_root=$(printf '%s' "$windows_path" | wslpath -u 2>/dev/null)
  fi

  if [[ ! -d "$onedrive_root" && -d "$windows_home" ]]; then
    candidates=("$windows_home"/OneDrive\ -\ *(N/))
    (( ${#candidates} == 1 )) && onedrive_root=${candidates[1]%/}
  fi

  if [[ ! -d "$onedrive_root" ]]; then
    candidates=(/mnt/c/Users/*/OneDrive\ -\ *(N/))
    (( ${#candidates} == 1 )) && onedrive_root=${candidates[1]%/}
  fi

  if [[ ! -d "$onedrive_root" && -d "$windows_home/OneDrive" ]]; then
    onedrive_root="$windows_home/OneDrive"
  fi

  [[ -d "$onedrive_root" ]] || return 0
  export ONEDRIVE_HOME="$onedrive_root"

  for link_path in Documents Pictures Downloads Desktop; do
    if [[ "$link_path" == Downloads ]]; then
      # OneDrive does not normally relocate Downloads. Use the Windows profile
      # that owns the detected OneDrive root, without hard-coding its name.
      target_path="${onedrive_root:h}/Downloads"
    else
      target_path="$onedrive_root/$link_path"
    fi
    [[ -d "$target_path" ]] || continue

    if [[ -L "$HOME/$link_path" ]]; then
      current_target=$(readlink -f "$HOME/$link_path" 2>/dev/null)
      if [[ "$current_target" == /mnt/c/Users/*/(OneDrive*/*|Downloads) && "$current_target" != "$target_path" ]]; then
        ln -sfn "$target_path" "$HOME/$link_path"
      fi
    elif [[ ! -e "$HOME/$link_path" ]]; then
      ln -s "$target_path" "$HOME/$link_path"
    fi
  done
}

setup_wsl_windows_folder_links
unset -f setup_wsl_windows_folder_links
