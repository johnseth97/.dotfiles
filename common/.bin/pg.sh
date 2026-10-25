#!/bin/sh
# Clipboard-independent OpenPGP message tools. Cryptography belongs to GPG;
# this script handles input, temporary public keys, and readable presentation.
# Dependencies: POSIX shell/text tools, mktemp, and GnuPG. No Python required.

# Color is presentation only: pipes and NO_COLOR always receive plain text.
red= green= cyan= reset=
if [ -t 1 ] && [ "${NO_COLOR+x}" != x ] && [ "${TERM:-}" != dumb ]; then
    red=$(printf '\033[1;31m'); green=$(printf '\033[1;32m')
    cyan=$(printf '\033[36m'); reset=$(printf '\033[0m')
fi

usage() {
    printf '%sPG — private messages, verifiable signatures%s\n\n' "$cyan" "$reset"
    cat <<'EOF'
Usage: pg.sh [--auto | --verify | --sign | --encrypt | --decrypt | --export-public] [options]
Read stdin, or use --file PATH. Content operations write only content to stdout.

Clipboard shortcuts (Zsh):
  pgpaste                 Detect, verify, or decrypt all clipboard PGP blocks
  pgsign                  Sign clipboard text, leaving it readable
  pgencrypt [RECIPIENT]    Sign and encrypt clipboard text; otherwise pick a key
  pgencrypt --unsigned    Encrypt without signing (explicit opt-out)
  pgopen                  Decrypt clipboard text and check embedded signatures
  pgcopy [--key ID]        Copy your PUBLIC certificate for others to use
EOF
    printf '\n%sHow PGP works%s\n' "$cyan" "$reset"
    cat <<'EOF'
  Encrypt to THEIR public key; only THEIR private key can decrypt it.
  Sign with YOUR private key; YOUR public key lets others verify it.
  A public certificate includes public signing/encryption keys and subkeys.
  Sharing public signing keys does NOT let anyone sign as you.
  Signed encryption puts the signature inside the encrypted message.
  Check fingerprints independently: a valid signature alone does not prove identity.
EOF
    printf '\n%sNever share your private keys — signing OR encryption.%s\n' "$red" "$reset"
    printf 'pgcopy/--export-public export only public material. No secret export option exists.\n'
    printf '\n%sOptions%s\n' "$cyan" "$reset"
    cat <<'EOF'
  --auto                  Detect signed/encrypted blocks (default)
  --verify                Only verify clear-signed blocks
  --encrypt               Sign AND encrypt (fails if signing is unavailable)
  --unsigned              Encrypt without signing; requires --encrypt
  --sign                  Clear-sign, or explicitly sign with --encrypt
  --export-public         Export your public certificate to stdout (no stdin)
  --recipient ID          Recipient fingerprint/email (repeatable)
  --self                  Encrypt to your own selected identity
  --key ID                Your signing/export identity; also used by --self
  --recipient-file PATH   Import public keys temporarily; select a recipient
  --raw | --repair        Verify original or repaired armor only (default: both)
  --save-keys | --no-save  Save temporary public keys, or suppress the save offer
  --offline               Disable missing-signing-key lookup
  --quiet                 Verification exit status only; no interactive prompts
  --verbose, -v           Show GPG diagnostics
  --self-test             Run isolated, offline tests using disposable keys
  --help, -h              Show this help without reading the clipboard

Recipient picker: existing keys, clipboard public key, file/directory, or yourself.
PG_CLIPBOARD_COMMAND supplies its clipboard reader; wrappers set this for you.
New public keys stay temporary unless you accept saving or use --save-keys.
Default keyserver: hkps://keys.openpgp.org (override with PG_KEYSERVER).
NO_COLOR disables terminal colors. GPG's agent/pinentry handles private keys.
EOF
}

fail() { printf 'pg: %s\n' "$*" >&2; exit 1; }
# Prevent terminal escapes/control bytes from clipboard text or key identities.
safe_text() { LC_ALL=C tr -d '\000-\010\013-\037\177'; }
log() { [ "$verbose" = yes ] && printf 'pg: %s\n' "$*" >&2; :; }
diagnostics() { if [ "$verbose" = yes ]; then safe_text < "$work/errors" >&2; fi; }

operation=auto sign=no encrypt=no mode=auto verbose=no quiet=no offline=no
save=ask key= recipient_file= input_file= self=no unsigned=no explicit_sign=no
# Repeated recipient arguments are stored after workspace creation below.
recipient_args=
while [ "$#" -gt 0 ]; do
    case $1 in
        --auto) operation=auto ;;
        --verify) operation=verify ;;
        --sign) sign=yes; explicit_sign=yes; operation=produce ;;
        --encrypt) encrypt=yes; operation=produce ;;
        --decrypt) operation=decrypt ;;
        --export-public) operation=export ;;
        --unsigned) unsigned=yes ;;
        --self-test) operation=test ;;
        --raw) mode=raw ;;
        --repair) mode=repair ;;
        --verbose|-v) verbose=yes ;;
        --quiet) quiet=yes ;;
        --offline) offline=yes ;;
        --save-keys) save=yes ;;
        --no-save) save=no ;;
        --self) self=yes ;;
        --key|--recipient|--recipient-file|--file)
            option=$1; shift
            [ "$#" -gt 0 ] && [ -n "$1" ] || fail "$option needs a value"
            case $1 in *'
'*) fail 'arguments cannot contain newlines' ;; esac
            case $option in
                --key) key=$1 ;;
                --recipient) recipient_args="${recipient_args}${1}
" ;;
                --recipient-file) recipient_file=$1 ;;
                --file) input_file=$1 ;;
            esac ;;
        --help|-h) usage; exit 0 ;;
        *) fail "unknown argument: $1 (see --help)" ;;
    esac
    shift
done
if [ "$operation" != produce ] && { [ "$sign" = yes ] || [ "$encrypt" = yes ]; }; then
    fail 'sign/encrypt cannot be combined with verify/decrypt/self-test'
fi
if [ "$unsigned" = yes ]; then
    [ "$encrypt" = yes ] || fail '--unsigned requires --encrypt'
    [ "$explicit_sign" = no ] || fail '--unsigned conflicts with --sign'
elif [ "$encrypt" = yes ]; then
    sign=yes
fi
command -v gpg >/dev/null 2>&1 || fail 'install GnuPG first'
umask 077
work=$(mktemp -d "${TMPDIR:-/tmp}/pg.XXXXXXXX") || exit 1
terminal_settings=
restore_terminal() {
    if [ -n "$terminal_settings" ]; then
        stty "$terminal_settings" <&3 2>/dev/null
        terminal_settings=
    fi
}
cleanup() {
    restore_terminal
    if command -v gpgconf >/dev/null 2>&1; then
        for temporary_home in "$work/keyring" "$work/recipient-home"; do
            [ ! -d "$temporary_home" ] || gpgconf --homedir "$temporary_home" --kill all >/dev/null 2>&1
        done
    fi
    rm -rf "$work"
}
trap cleanup 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
: > "$work/imported"
: > "$work/lookups"
printf '%s' "$recipient_args" > "$work/recipients"
# Opening the terminal once avoids accidentally consuming message data as answers.
interactive=no
if [ "$quiet" = no ] && ( : <> /dev/tty ) 2>/dev/null; then
    exec 3<> /dev/tty
    interactive=yes
fi
prompt() {
    [ "$interactive" = yes ] || fail 'recipient/input required in noninteractive mode'
    # Pinentry or an interrupted terminal program can leave Enter unmapped.
    # Save exactly what we inherited; use normal line input only for the prompt.
    terminal_settings=$(stty -g <&3) || fail 'cannot read terminal settings'
    stty icanon isig echo icrnl -igncr -inlcr <&3 || fail 'cannot prepare terminal input'
    printf '%s\n> ' "$1" >&3
    IFS= read -r answer <&3
    read_result=$?
    restore_terminal
    [ "$read_result" -eq 0 ] || fail 'input cancelled'
}

# Use an isolated home for public-key imports. Seed it with existing public
# keys so mixed-signature messages can use both local and retrieved identities.
prepare_keyring() {
    [ -d "$work/keyring" ] && return 0
    mkdir "$work/keyring" || return 1
    gpg --batch --export > "$work/local-keys" 2> "$work/errors" || return 1
    if [ -s "$work/local-keys" ]; then
        gpg --no-options --homedir "$work/keyring" --batch --import "$work/local-keys" > /dev/null 2> "$work/errors" || return 1
    fi
}
remember_imports() {
    awk '$2=="IMPORT_OK" {print $4}' "$work/import-status" >> "$work/imported"
    sort -u "$work/imported" > "$work/unique"
    mv "$work/unique" "$work/imported"
}
# Import public material without modifying the normal keyring. GPG rejects
# secret-key input in import-export mode; do not import private keys here.
import_public() {
    prepare_keyring || fail 'cannot prepare temporary keyring'
    gpg --no-options --batch --import-options import-export --import -- "$1" > "$work/public-only" 2> "$work/errors"
    rc=$?; diagnostics
    [ "$rc" -eq 0 ] && [ -s "$work/public-only" ] || fail 'no usable public key in that input; supply a public-key export'
    gpg --no-options --homedir "$work/keyring" --batch --status-fd 1 --import "$work/public-only" > "$work/import-status" 2> "$work/errors"
    rc=$?; diagnostics
    [ "$rc" -eq 0 ] || fail 'public key import failed'
    remember_imports
}
save_imports() {
    [ -s "$work/imported" ] || return 0
    case $save in
        no) return 0 ;;
        ask)
            [ "$interactive" = yes ] || return 0
            printf '\nTemporary public keys (saving does not assign identity trust):\n' >&3
            cat "$work/imported" >&3
            prompt 'Save these public keys to your normal keyring? [y/N] '
            case $answer in y|Y|yes) ;; *) return 0 ;; esac ;;
    esac
    set --
    while IFS= read -r fingerprint; do set -- "$@" "$fingerprint"; done < "$work/imported"
    gpg --no-options --homedir "$work/keyring" --batch --export "$@" > "$work/save-keys" 2> "$work/errors" || return 1
    gpg --batch --import "$work/save-keys" >/dev/null 2> "$work/errors"
    rc=$?; diagnostics
    [ "$rc" -eq 0 ] || { printf 'pg: saving public keys failed\n' >&2; return 1; }
    [ "$quiet" = yes ] || printf 'pg: public keys saved (trust unchanged).\n' >&2
}

# Record machine-readable status separately; never parse translated diagnostics.
check_signature() {
    if [ "$source" = local ]; then
        gpg --batch --no-auto-key-retrieve --no-auto-key-import --status-fd 1 --verify "$candidate" > "$work/status" 2> "$work/errors"
    else
        gpg --no-options --homedir "$work/keyring" --batch --no-auto-key-retrieve --no-auto-key-import --status-fd 1 --verify "$candidate" > "$work/status" 2> "$work/errors"
    fi
    check_rc=$?; diagnostics
    return "$check_rc"
}
lookup_missing() {
    [ "$offline" = no ] || return 0
    # ERRSIG includes the full fingerprint when supplied by the signature.
    awk '$2=="ERRSIG" && $8==9 {id=$3; if (length($9)==40 || length($9)==64) id=$9;
        if (id ~ /^[0-9A-Fa-f]+$/ && (length(id)==16 || length(id)==40 || length(id)==64)) print id}' "$work/status" > "$work/missing"
    [ -s "$work/missing" ] || return 0
    prepare_keyring || return 1
    while IFS= read -r fingerprint; do
        grep -F -x "$fingerprint" "$work/lookups" >/dev/null && continue
        printf '%s\n' "$fingerprint" >> "$work/lookups"
        log "looking up $fingerprint on ${PG_KEYSERVER:-hkps://keys.openpgp.org}"
        gpg --no-options --homedir "$work/keyring" --batch --status-fd 1 \
            --keyserver "${PG_KEYSERVER:-hkps://keys.openpgp.org}" --keyserver-options timeout=15 \
            --recv-keys "$fingerprint" > "$work/import-status" 2> "$work/errors"
        lookup_rc=$?; diagnostics
        remember_imports
        if [ "$lookup_rc" -ne 0 ]; then
            lookup_note='Key unavailable or lookup/import failed on the keyserver.'
        fi
    done < "$work/missing"
}
verify_candidate() {
    source=local
    check_signature && return 0
    if grep '^\[GNUPG:\] NO_PUBKEY ' "$work/status" >/dev/null; then
        lookup_missing
        if [ -d "$work/keyring" ]; then
            source=temporary
            check_signature && return 0
        fi
    fi
    return 1
}

# AWK is kept in named functions rather than compressed pipelines. Armor repair
# changes envelopes and base64 whitespace only, never signed message lines.
extract_blocks() {
    awk -v dir="$work" -v auto="$operation" '
    BEGIN {signed="-----BEGIN PGP SIGNED MESSAGE-----"; encrypted="-----BEGIN PGP MESSAGE-----"; end="-----END PGP SIGNATURE-----"}
    {
        line=$0
        if (line ~ /^- /) {if (active) text=text line "\n"; next}
        while (length(line)) {
            begin=signed; b=index(line,begin)
            c=(auto=="auto" ? index(line,encrypted) : 0)
            if(c && (!b || c<b)) {begin=encrypted; b=c}
            e=index(line,end)
            if (b && (!e || b<e)) {
                if (active) incomplete++
                active=1; text=begin
                end=(begin==encrypted ? "-----END PGP MESSAGE-----" : "-----END PGP SIGNATURE-----")
                line=substr(line,b+length(begin)); continue
            }
            if (e) {
                if (active) {
                    file=dir "/block." ++count
                    print text substr(line,1,e+length(end)-1) > file; close(file)
                    active=0; text=""
                }
                line=substr(line,e+length(end)); continue
            }
            if (active) text=text line
            line=""
        }
        if (active) text=text "\n"
    }
    END {if(active) incomplete++; print count+0, incomplete+0 > (dir "/counts")}
    ' "$work/input"
}
repair_armor() {
    awk '
    BEGIN {state="start"}
    {sub(/\r$/, "")}
    state=="start" {
        sub(/^-----BEGIN PGP SIGNED MESSAGE-----[ \t]*/, "")
        print "-----BEGIN PGP SIGNED MESSAGE-----"; state="hash"
        if ($0=="") next
    }
    state=="hash" {
        if ($0 !~ /^Hash:/) exit 1
        print; print ""; state="separator"; next
    }
    state=="separator" {state="body"; if ($0=="") next}
    state=="body" {
        if ($0 ~ /^-----BEGIN PGP SIGNATURE-----/) {
            sub(/^-----BEGIN PGP SIGNATURE-----[ \t]*/, "")
            print "-----BEGIN PGP SIGNATURE-----"; state="armor"
        } else {print; next}
    }
    state=="armor" {
        if ($0 ~ /^[A-Za-z][A-Za-z0-9-]*:/ && compact=="") {print; next}
        end=index($0,"-----END PGP SIGNATURE-----")
        if (end) {$0=substr($0,1,end-1); finished=1}
        gsub(/[ \t]/, ""); compact=compact $0
    }
    END {
        if (!finished || compact=="" || compact ~ /[^A-Za-z0-9+\/=]/) exit 1
        if (substr(compact,length(compact)-4,1)=="=") {
            checksum=substr(compact,length(compact)-4); compact=substr(compact,1,length(compact)-5)
        }
        print ""
        for(i=1;i<=length(compact);i+=64) print substr(compact,i,64)
        if(checksum!="") print checksum
        print "-----END PGP SIGNATURE-----"
    }' "$1" > "$work/repaired"
}
message_body() {
    if [ "${decrypted:-no}" = yes ]; then
        safe_text < "$work/output"
        # Human reports end with a newline even if the plaintext does not.
        printf '\n'
        return
    fi
    awk '
    NR==1 {sub(/^-----BEGIN PGP SIGNED MESSAGE-----[ \t]*/, ""); if($0=="") next}
    !body && /^Hash:/ {next}
    !body {body=1; if($0=="") next}
    /^-----BEGIN PGP SIGNATURE-----/ {exit}
    {sub(/\r$/, ""); sub(/^- /, ""); print}
    ' "$candidate" | safe_text
}
report() {
    [ "$quiet" = yes ] && return 0
    if [ "$verified" = yes ]; then
        if [ "${decrypted:-no}" = yes ]; then
            printf '%s✓ Decrypted · signature verified%s' "$green" "$reset"
        else
            printf '%s✓ Signature verified%s' "$green" "$reset"
        fi
        [ "$repaired" = yes ] && printf ' · armor repaired'
        printf '\n'
    else
        printf '%s✗ Signature not verified%s\n' "$red" "$reset"
    fi
    awk -v good="$verified" '
    $2 ~ /^(GOODSIG|BADSIG|EXPKEYSIG|EXPSIG|REVKEYSIG)$/ {
        name=$0; sub(/^[^ ]+ [^ ]+ [^ ]+ /,"",name)
        printf "  %s: %s\n",(good=="yes"?"Signer":"Claimed signer"),name
    }
    $2=="VALIDSIG" {print "  Key:    " $3; print "  Signed: " $4 " (UTC)"}
    $2=="NO_PUBKEY" {print "  Missing key: " $3}
    ' "$work/status" | safe_text | while IFS= read -r line; do
        case $line in
            '  Signer:'*|'  Claimed signer:'*) printf '%s%s%s\n' "$cyan" "$line" "$reset" ;;
            *) printf '%s\n' "$line" ;;
        esac
    done
    if [ "$verified" = yes ]; then
        printf '  Source: %s\n' "$source keyring"
        if grep -E '^\[GNUPG:\] TRUST_(FULLY|ULTIMATE)' "$work/status" >/dev/null; then
            printf '  Trust:  trusted by local GPG configuration\n'
        else
            printf '  Trust:  signer identity unconfirmed\n'
        fi
        printf '\nMessage\n'; body_color=$cyan
    else
        if grep '^\[GNUPG:\] BADSIG ' "$work/status" >/dev/null; then
            printf '  Message does not match the signature.\n'
        elif grep '^\[GNUPG:\] NO_PUBKEY ' "$work/status" >/dev/null; then
            printf '  %s\n' "${lookup_note:-No usable signing key available.}"
        else
            printf '  Invalid, unsupported, expired, or revoked signature/message.\n'
        fi
        printf '  Use --verbose for GPG diagnostics.\n\n%sMessage · UNVERIFIED%s\n' "$red" "$reset"
        body_color=$red
    fi
    message_body | while IFS= read -r line; do printf '%s  │ %s%s\n' "$body_color" "$line" "$reset"; done
}
verify_messages() {
    extract_blocks
    read -r count incomplete < "$work/counts"
    [ "$count" -gt 0 ] || { [ "$quiet" = yes ] || printf '✗ No complete supported PGP message blocks found.\n'; return 1; }
    index=1; failures=0
    while [ "$index" -le "$count" ]; do
        if [ "$quiet" = no ] && [ "$count" -gt 1 ]; then printf '\n── Message %s/%s ──\n' "$index" "$count"; fi
        candidate=$work/block.$index
        verified=no; repaired=no; lookup_note=; source=local; decrypted=no
        : > "$work/status"
        if [ "$operation" = auto ] && grep '^-----BEGIN PGP MESSAGE-----' "$candidate" >/dev/null; then
            if decrypt_candidate; then
                decrypted=yes
                if grep '^\[GNUPG:\] VALIDSIG ' "$work/status" >/dev/null; then
                    verified=yes
                    report
                elif [ "$quiet" = no ]; then
                    printf '%s✓ Decrypted · unsigned%s\n' "$green" "$reset"
                    printf '  No signature: sender identity is unverified.\n\n%sMessage · UNVERIFIED%s\n' "$red" "$reset"
                    message_body | while IFS= read -r line; do printf '%s  │ %s%s\n' "$red" "$line" "$reset"; done
                fi
            else
                failures=$((failures+1))
                [ "$quiet" = yes ] || printf '%s✗ Decryption/signature check failed; plaintext withheld.%s\n  Use --verbose for GPG diagnostics.\n' "$red" "$reset"
            fi
        else
            if [ "$mode" != repair ] && verify_candidate; then verified=yes; fi
            if [ "$verified" = no ] && [ "$mode" != raw ] && repair_armor "$candidate"; then
                candidate=$work/repaired; repaired=yes
                if verify_candidate; then verified=yes; fi
            fi
            report
            [ "$verified" = yes ] || failures=$((failures+1))
        fi
        index=$((index+1))
    done
    if [ "$quiet" = no ]; then
        [ "$incomplete" -eq 0 ] || printf '\n✗ %s incomplete PGP message block(s).\n' "$incomplete"
        if [ "$count" -gt 1 ]; then
            if [ "$operation" = auto ]; then
                printf '\n%s/%s messages processed successfully.\n' "$((count-failures))" "$count"
            else
                printf '\n%s/%s complete messages verified.\n' "$((count-failures))" "$count"
            fi
        fi
    fi
    [ "$failures" -eq 0 ] && [ "$incomplete" -eq 0 ]
}

# Key listing emits primary fingerprints with identity and usable capabilities.
# A primary key may delegate encryption/signing to a subkey (uppercase E/S).
key_rows() {
    awk -F: -v capability="$1" '
    function emit() {if(fpr!="" && usable && (capability=="" || index(tolower(caps),capability))) print fpr "\t" uid}
    $1=="pub" || $1=="sec" {emit(); fpr=""; uid=""; caps=$12; usable=($2 !~ /[redi]/ && $12 !~ /D/)}
    $1=="fpr" && fpr=="" {fpr=$10}
    $1=="uid" && uid=="" && $2 !~ /[re]/ {uid=$10}
    END {emit()}'
}
list_public() {
    if [ -d "$work/keyring" ]; then
        gpg --no-options --homedir "$work/keyring" --batch --with-colons --list-keys 2> "$work/errors"
    else
        gpg --batch --with-colons --list-keys 2> "$work/errors"
    fi
}
select_row() {
    rows=$1
    [ -s "$rows" ] || fail 'no usable encryption keys found'
    awk -F '\t' '{printf "  %d) %s  [%s]\n",NR,$2,$1}' "$rows" | safe_text >&3
    while :; do
        prompt 'Recipient number (or q to cancel): '
        case $answer in
            q|Q) fail 'selection cancelled' ;;
            ''|*[!0-9]*) printf 'Enter a listed number, or q to cancel.\n' >&3; continue ;;
        esac
        selected=$(awk -F '\t' -v n="$answer" 'NR==n {print $1}' "$rows")
        [ -n "$selected" ] && break
        printf 'No recipient with that number.\n' >&3
    done
    printf '%s\n' "$selected" >> "$work/recipients"
}
default_identity() {
    [ -n "$key" ] && return 0
    # GPG itself remains responsible for passphrases, agents, and hardware keys.
    if command -v gpgconf >/dev/null 2>&1; then
        key=$(gpgconf --list-options gpg 2>/dev/null | awk -F: '$1=="default-key" {sub(/^"/,"",$10); print $10}')
    fi
    [ -n "$key" ] && return 0
    gpg --batch --with-colons --list-secret-keys 2> "$work/errors" | key_rows "${1:-s}" > "$work/identities"
    identities=$(wc -l < "$work/identities" | tr -d ' ')
    [ "$identities" -eq 1 ] || fail 'set GPG default-key or supply --key (no unambiguous signing identity)'
    key=$(awk -F '\t' 'NR==1 {print $1}' "$work/identities")
}
path_key() {
    path=$1
    case $path in '~') path=$HOME ;; '~/'*) path=$HOME/${path#\~/} ;; esac
    if [ -d "$path" ]; then
        # Inspect immediate files, not extensions: keys need not end in .asc.
        : > "$work/keyfiles"
        for file in "$path"/*; do
            [ -f "$file" ] || continue
            case $file in *'
'*) continue ;; esac
            if gpg --no-options --batch --with-colons --show-keys -- "$file" > "$work/probe" 2>/dev/null && grep '^pub:' "$work/probe" >/dev/null; then
                printf '%s\n' "$file" >> "$work/keyfiles"
            fi
        done
        [ -s "$work/keyfiles" ] || fail 'no public-key files found in directory'
        awk '{printf "  %d) %s\n",NR,$0}' "$work/keyfiles" | safe_text >&3
        prompt 'Key file number: '
        case $answer in ''|*[!0-9]*) fail 'invalid file selection' ;; esac
        path=$(awk -v n="$answer" 'NR==n' "$work/keyfiles")
    fi
    [ -f "$path" ] || fail 'key file not found'
    import_public "$path"
    # Select only keys present in the chosen file, not all seeded local keys.
    gpg --no-options --batch --with-colons --show-keys "$work/public-only" 2> "$work/errors" | key_rows e > "$work/choices"
    select_row "$work/choices"
}
pick_recipient() {
    [ "$interactive" = yes ] || fail 'use --recipient or --self when no terminal is available'
    list_public | key_rows e > "$work/choices"
    printf 'Encryption recipients:\n' >&3
    awk -F '\t' '{printf "  %d) %s  [%s]\n",NR,$2,$1}' "$work/choices" | safe_text >&3
    printf '  c) Public key from clipboard\n  p) Key file or directory path\n  s) Encrypt to yourself\n  q) Cancel\n' >&3
    while :; do
        prompt 'Recipient: '
        case $answer in
            c|C)
                [ -n "${PG_CLIPBOARD_COMMAND:-}" ] || fail 'set PG_CLIPBOARD_COMMAND for clipboard key import'
                prompt 'Copy the recipient public key, then press Enter: '
                # This is trusted user configuration, never derived from a message.
                sh -c "$PG_CLIPBOARD_COMMAND" > "$work/clipboard-key" || fail 'clipboard read failed'
                import_public "$work/clipboard-key"
                gpg --no-options --batch --with-colons --show-keys "$work/public-only" 2> "$work/errors" | key_rows e > "$work/choices"
                select_row "$work/choices" ;;
            p|P) prompt 'Key file or directory path: '; path_key "$answer" ;;
            s|S) self=yes ;;
            q|Q) fail 'selection cancelled' ;;
            ''|*[!0-9]*) printf 'Enter a recipient number or c, p, s, q.\n' >&3; continue ;;
            *) selected=$(awk -F '\t' -v n="$answer" 'NR==n {print $1}' "$work/choices")
               if [ -z "$selected" ]; then printf 'No recipient with that number.\n' >&3; continue; fi
               printf '%s\n' "$selected" >> "$work/recipients" ;;
        esac
        break
    done
}
export_public() {
    default_identity e
    gpg --batch --with-colons --list-secret-keys -- "$key" 2> "$work/errors" | key_rows e > "$work/export-identity"
    matches=$(wc -l < "$work/export-identity" | tr -d ' ')
    [ "$matches" -eq 1 ] || fail 'choose one of your encryption-capable identities with --key'
    fingerprint=$(awk -F '\t' 'NR==1 {print $1}' "$work/export-identity")
    # --export is public-only, including all public signing/encryption subkeys.
    gpg --batch --armor --export "$fingerprint" > "$work/public-export" 2> "$work/errors"
    rc=$?; diagnostics
    [ "$rc" -eq 0 ] && [ -s "$work/public-export" ] || fail 'public certificate export failed'
    cat "$work/public-export"
}

produce_message() {
    if [ "$encrypt" = yes ]; then
        if [ -n "$recipient_file" ]; then
            if [ -f "$recipient_file" ] && [ -s "$work/recipients" ]; then
                import_public "$recipient_file"
            else
                [ "$interactive" = yes ] || fail 'use --recipient with a key file, or select interactively'
                path_key "$recipient_file"
            fi
        fi
        if [ ! -s "$work/recipients" ] && [ "$self" = no ]; then pick_recipient; fi
    fi
    if [ "$sign" = yes ]; then default_identity s
    elif [ "$self" = yes ]; then default_identity e; fi
    [ "$self" = no ] || printf '%s\n' "$key" >> "$work/recipients"
    set -- --batch --yes --no-auto-key-retrieve --no-auto-key-import --armor --output "$work/output"
    # Retain the normal secret-key store/agent; add only the temporary public
    # keyring. Private keys never move into the temporary home.
    if [ -d "$work/keyring" ]; then set -- "$@" --no-default-keyring --keyring "$work/keyring/pubring.kbx"; fi
    [ "$sign" = no ] || set -- "$@" --local-user "$key"
    if [ "$encrypt" = yes ]; then
        # Explicit recipient selection authorizes use of this key, not its UID.
        # Resolve each selector and reject ambiguous or unusable matches first.
        : > "$work/resolved"
        while IFS= read -r recipient; do
            if [ -d "$work/keyring" ]; then
                gpg --no-options --homedir "$work/keyring" --batch --with-colons --list-keys -- "$recipient" 2> "$work/errors"
            else
                gpg --batch --with-colons --list-keys -- "$recipient" 2> "$work/errors"
            fi | key_rows e > "$work/matches"
            matches=$(wc -l < "$work/matches" | tr -d ' ')
            [ "$matches" -eq 1 ] || fail "recipient is ambiguous or has no usable encryption key: $recipient"
            awk -F '\t' '{print $1}' "$work/matches" >> "$work/resolved"
        done < "$work/recipients"
        while IFS= read -r fingerprint; do set -- "$@" --recipient "$fingerprint"; done < "$work/resolved"
        set -- "$@" --trust-model always
        [ "$sign" = no ] || set -- "$@" --sign
        set -- "$@" --encrypt
    else
        set -- "$@" --clearsign
    fi
    gpg "$@" -- "$work/input" 2> "$work/errors"
    rc=$?; diagnostics
    [ "$rc" -eq 0 ] || fail 'signing/encryption failed (use --verbose)'
    cat "$work/output"
}
decrypt_candidate() {
    source=local
    gpg --batch --yes --no-auto-key-retrieve --no-auto-key-import --status-fd 1 --output "$work/output" --decrypt "$candidate" > "$work/status" 2> "$work/errors"
    rc=$?; diagnostics
    if grep '^\[GNUPG:\] NO_PUBKEY ' "$work/status" >/dev/null; then
        lookup_missing
        if [ -d "$work/keyring" ]; then
            source=temporary
            gpg --batch --yes --no-auto-key-retrieve --no-auto-key-import --no-default-keyring --keyring "$work/keyring/pubring.kbx" --status-fd 1 --output "$work/output" --decrypt "$candidate" > "$work/status" 2> "$work/errors"
            rc=$?; diagnostics
        fi
    fi
    [ "$rc" -eq 0 ] && grep '^\[GNUPG:\] DECRYPTION_OKAY' "$work/status" >/dev/null
}
decrypt_message() {
    candidate=$work/input
    decrypt_candidate || fail 'decryption/signature verification failed; plaintext withheld (use --verbose)'
    cat "$work/output"
}

self_test() {
    # Entire test uses a disposable home. No personal keys or network needed.
    mkdir "$work/keyring"
    export GNUPGHOME=$work/keyring
    gpg --batch --pinentry-mode loopback --passphrase '' --quick-generate-key 'PG Self Test <pg-test@example.invalid>' rsa2048 sign,encrypt 0 > /dev/null 2> "$work/errors" || fail 'test key generation failed'
    printf 'Portable PGP round trip\nSecond line\n' > "$work/plain"
    sh "$0" --sign --file "$work/plain" > "$work/signed" || fail 'self-test signing'
    sh "$0" --verify --quiet --offline --file "$work/signed" || fail 'self-test verification'
    sh "$0" --encrypt --self --file "$work/plain" > "$work/cipher" || fail 'self-test encryption'
    gpg --batch --yes --status-fd 1 --output "$work/test-decoded" --decrypt "$work/cipher" > "$work/test-status" 2>/dev/null || fail 'self-test default signed ciphertext'
    grep '^\[GNUPG:\] VALIDSIG ' "$work/test-status" >/dev/null || fail 'self-test encryption was not signed by default'
    cp "$work/cipher" "$work/signed-cipher"
    sh "$0" --auto --offline --no-save --file "$work/cipher" > "$work/auto-report" || fail 'self-test auto signed encryption'
    grep 'Decrypted · signature verified' "$work/auto-report" >/dev/null || fail 'self-test auto signature label'
    grep 'Portable PGP round trip' "$work/auto-report" >/dev/null || fail 'self-test auto plaintext'

    sh "$0" --decrypt --file "$work/cipher" > "$work/decoded" || fail 'self-test decryption'
    cmp "$work/plain" "$work/decoded" || fail 'self-test plaintext mismatch'
    sh "$0" --encrypt --unsigned --self --file "$work/plain" > "$work/cipher" || fail 'self-test signed encryption'
    gpg --batch --yes --status-fd 1 --output "$work/test-decoded" --decrypt "$work/cipher" > "$work/test-status" 2>/dev/null || fail 'self-test unsigned ciphertext'
    if grep '^\[GNUPG:\] VALIDSIG ' "$work/test-status" >/dev/null; then fail 'self-test unsigned still signed'; fi
    sh "$0" --auto --offline --no-save --file "$work/cipher" > "$work/auto-report" || fail 'self-test auto unsigned encryption'
    grep 'Decrypted · unsigned' "$work/auto-report" >/dev/null || fail 'self-test unsigned label'
    { printf 'Surrounding text\n'; cat "$work/signed" "$work/signed-cipher" "$work/cipher"; } > "$work/auto-mixed"
    sh "$0" --auto --offline --no-save --file "$work/auto-mixed" > "$work/auto-report" || fail 'self-test mixed auto blocks'
    grep '3/3 messages processed successfully' "$work/auto-report" >/dev/null || fail 'self-test mixed count'
    { printf '%s\n' '-----BEGIN PGP MESSAGE-----' invalid '-----END PGP MESSAGE-----' ; cat "$work/signed"; } > "$work/auto-bad"
    if sh "$0" --auto --offline --no-save --file "$work/auto-bad" > "$work/auto-report"; then fail 'self-test auto invalid cipher'; fi
    grep '1/2 messages processed successfully' "$work/auto-report" >/dev/null || fail 'self-test auto stopped after failure'

    sh "$0" --decrypt --file "$work/cipher" > "$work/decoded" || fail 'self-test signed decryption'
    cmp "$work/plain" "$work/decoded" || fail 'self-test signed plaintext mismatch'
    sed 's/Portable/Tampered/' "$work/signed" > "$work/tampered"
    if sh "$0" --verify --quiet --offline --file "$work/tampered"; then fail 'self-test accepted tampering'; fi
    # Flatten only the armor, leaving signed body line breaks intact.
    awk '
    NR==1 {printf "%s ",$0; next}
    /^-----BEGIN PGP SIGNATURE-----/ {armor=1; print; next}
    armor {printf "%s ",$0; next}
    {print}
    END {print ""}' "$work/signed" > "$work/broken"
    sh "$0" --verify --quiet --offline --file "$work/broken" || fail 'self-test armor repair'
    if sh "$0" --verify --raw --quiet --offline --file "$work/broken"; then fail 'self-test raw accepted broken armor'; fi
    { printf 'Surrounding text\n'; cat "$work/signed" "$work/broken"; printf 'Trailing text\n'; } > "$work/multiple"
    sh "$0" --verify --quiet --offline --file "$work/multiple" || fail 'self-test multiple blocks'
    cat "$work/tampered" >> "$work/multiple"
    if sh "$0" --verify --quiet --offline --file "$work/multiple"; then fail 'self-test mixed results'; fi
    { cat "$work/signed"; printf '\n-----BEGIN PGP SIGNED MESSAGE-----\nIncomplete'; } > "$work/partial"
    if sh "$0" --verify --quiet --offline --file "$work/partial"; then fail 'self-test incomplete block'; fi
    mkdir "$work/empty"
    if GNUPGHOME="$work/empty" sh "$0" --verify --quiet --offline --file "$work/signed"; then fail 'self-test missing key'; fi
    printf 'not encrypted\n' > "$work/invalid"
    if sh "$0" --decrypt --file "$work/invalid" > "$work/leak" 2>/dev/null; then fail 'self-test invalid ciphertext'; fi
    [ ! -s "$work/leak" ] || fail 'self-test released failed plaintext'
    # A second identity exercises explicit recipient files and opt-in saving.
    mkdir "$work/recipient-home"
    GNUPGHOME="$work/recipient-home" gpg --batch --pinentry-mode loopback --passphrase '' --quick-generate-key 'PG Recipient <recipient@example.invalid>' rsa2048 sign,encrypt 0 >/dev/null 2> "$work/errors" || fail 'test recipient generation'
    GNUPGHOME="$work/recipient-home" gpg --batch --export > "$work/recipient.pub" 2>/dev/null
    recipient_id=$(GNUPGHOME="$work/recipient-home" gpg --batch --with-colons --list-keys 2>/dev/null | awk -F: '$1=="fpr" {print $10; exit}')
    sh "$0" --encrypt --unsigned --recipient-file "$work/recipient.pub" --recipient "$recipient_id" --no-save --file "$work/plain" > "$work/cipher" || fail 'self-test temporary recipient'
    if gpg --batch --list-keys "$recipient_id" >/dev/null 2>&1; then fail 'self-test temporary key persisted'; fi
    GNUPGHOME="$work/recipient-home" sh "$0" --decrypt --file "$work/cipher" > "$work/decoded" || fail 'self-test recipient decryption'
    cmp "$work/plain" "$work/decoded" || fail 'self-test recipient plaintext mismatch'
    sh "$0" --encrypt --unsigned --recipient-file "$work/recipient.pub" --recipient "$recipient_id" --save-keys --quiet --file "$work/plain" > "$work/cipher" || fail 'self-test save key'
    gpg --batch --list-keys "$recipient_id" >/dev/null 2>&1 || fail 'self-test saved key missing'
    if gpg --batch --list-secret-keys "$recipient_id" 2>/dev/null | grep '^sec' >/dev/null; then fail 'self-test imported private key'; fi
    if command -v gpgconf >/dev/null 2>&1; then gpgconf --homedir "$work/recipient-home" --kill all >/dev/null 2>&1; fi
    sh "$0" --export-public > "$work/exported-public" || fail 'self-test public export'
    grep '^-----BEGIN PGP PUBLIC KEY BLOCK-----' "$work/exported-public" >/dev/null || fail 'self-test public armor missing'
    gpg --batch --list-packets "$work/exported-public" > "$work/packets" 2>/dev/null || fail 'self-test public packets'
    if grep 'secret.*key packet' "$work/packets" >/dev/null; then fail 'self-test secret material exported'; fi
    if GNUPGHOME="$work/empty" sh "$0" --encrypt --recipient-file "$work/recipient.pub" --recipient "$recipient_id" --no-save --file "$work/plain" > "$work/leak" 2>/dev/null; then fail 'self-test silently omitted signature'; fi
    [ ! -s "$work/leak" ] || fail 'self-test emitted ciphertext without signing key'
    GNUPGHOME="$work/empty" sh "$0" --encrypt --unsigned --recipient-file "$work/recipient.pub" --recipient "$recipient_id" --no-save --file "$work/plain" > "$work/cipher" || fail 'self-test unsigned without private key'
    printf 'PASS: signing, encryption, signed encryption, exact round trips, tampering,\n'
    printf '      repair, multiple/mixed/incomplete blocks, missing keys, failed-output isolation,\n'
    printf '      temporary recipient imports, explicit saving, public-only export,\n'
    printf '      default signing, unsigned opt-out, and missing-signing-key failure.\n'
}

if [ "$operation" = test ]; then self_test; exit $?; fi
if [ "$operation" = export ]; then export_public; exit $?; fi
# Capture the message before any recipient or clipboard-key prompts.
if [ -n "$input_file" ]; then cat < "$input_file" > "$work/input" || fail 'cannot read input file'
else cat > "$work/input" || fail 'cannot read stdin'; fi
case $operation in
    auto|verify) verify_messages; result=$? ;;
    produce) produce_message; result=$? ;;
    decrypt) decrypt_message; result=$? ;;
esac
save_imports || result=1
exit "$result"
