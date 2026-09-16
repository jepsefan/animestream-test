#!/usr/bin/env bash
# Per-user Linux installer. No sudo or Python required.
set -euo pipefail

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
usage() {
    echo 'Usage: bash install-linux.sh [--version TAG | --bundle PATH]'
    echo 'Opens an interactive menu. Run as your normal user, without sudo.'
    echo 'For automation: bash install-linux.sh {install|update|uninstall} [--version TAG | --bundle PATH]'
}
# Read the controlling terminal, not stdin: stdin may contain this script from curl.
prompt() {
    printf '%s' "$1" >&8
    if ! IFS= read -r answer <&8; then
        printf '\nCancelled.\n' >&8
        exit 0
    fi
}
installer_menu() {
    local answer choice
    while :; do
        printf '\n  animestream | Linux installer\n  --------------------------------\n' >&8
        if [[ $installed == true ]]; then
            printf '  Status: installed\n\n  1) Update\n  2) Uninstall\n' >&8
        else
            printf '  Status: not installed\n\n  1) Install\n' >&8
        fi
        printf '  q) Quit\n\n' >&8
        prompt 'Choose an option: '
        case "$answer" in
            1)
                if [[ $installed == true ]]; then action=update; else action=install; fi
                break ;;
            2)
                if [[ $installed == true ]]; then action=uninstall; break; fi ;;
            q|Q) printf 'Cancelled.\n' >&8; exit 0 ;;
        esac
        printf 'Please choose one of the listed options.\n' >&8
    done
    if [[ $action == uninstall ]]; then
        printf '\nClose animestream before uninstalling. Settings and downloads will be kept.\n' >&8
        prompt 'Uninstall animestream? [y/N]: '
        case "$answer" in
            y|Y|yes|YES) return ;;
            *) printf 'Cancelled.\n' >&8; exit 0 ;;
        esac
    fi
    if [[ -z $tag && -z $bundle ]]; then
        while :; do
            printf '\n  Install source\n  --------------------------------\n  1) Latest stable release (default)\n  2) Specific release tag\n  3) Local ZIP or bundle directory\n  q) Quit\n\n' >&8
            prompt 'Choose a source [1]: '
            choice=$answer
            case "$choice" in
                ''|1) break ;;
                2)
                    prompt 'Release tag (for example, v1.4.8-beta1): '
                    if [[ -n $answer ]]; then tag=$answer; break; fi
                    printf 'A release tag is required.\n' >&8 ;;
                3)
                    prompt 'Bundle path (without quotes): '
                    # Expand only a leading ~/, never evaluate shell input.
                    case "$answer" in '~/'*) answer=$HOME/${answer:2} ;; esac
                    if [[ -n $answer && ( -f $answer || -d $answer ) ]]; then
                        bundle=$answer
                        break
                    fi
                    printf 'Enter an existing ZIP file or bundle directory.\n' >&8 ;;
                q|Q) printf 'Cancelled.\n' >&8; exit 0 ;;
                *) printf 'Please choose one of the listed options.\n' >&8 ;;
            esac
        done
    fi
    printf '\n  Action: %s\n' "$action" >&8
    if [[ -n $bundle ]]; then
        printf '  Bundle: %s\n' "$bundle" >&8
    else
        printf '  Release: %s\n' "${tag:-latest stable}" >&8
    fi
    printf '  Close animestream before continuing.\n\n' >&8
    prompt 'Continue? [Y/n]: '
    case "$answer" in
        ''|y|Y|yes|YES) ;;
        *) printf 'Cancelled.\n' >&8; exit 0 ;;
    esac
}
action=
case "${1:-}" in
    install|update|uninstall) action=$1; shift ;;
esac
tag= bundle=
while (($#)); do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --version|--bundle)
            (($# >= 2)) && [[ -n $2 ]] || die "$1 requires a value"
            [[ -z $tag && -z $bundle ]] || die 'Choose only one source option'
            if [[ $1 == --version ]]; then tag=$2; else bundle=$2; fi
            shift 2 ;;
        *) die "Unknown option: $1" ;;
    esac
done
[[ $action != uninstall || ( -z $tag && -z $bundle ) ]] || die 'uninstall takes no source options'
[[ $(uname -s) == Linux ]] || die 'This installer must be run on Linux'
((EUID != 0)) || die 'Run as your normal user, without sudo'
command -v flock >/dev/null || die 'Install flock (util-linux) first'
[[ $HOME == /* ]] || die 'HOME must be absolute'
data=${XDG_DATA_HOME:-$HOME/.local/share}
[[ $data == /* ]] || die 'XDG_DATA_HOME must be absolute'
# Keep desktop file escaping unambiguous for unusual home directories.
[[ $data != *[$'\n\r\t']* && $data != *'='* ]] || die 'Unsupported data directory characters'
mkdir -p -- "$HOME/.cache"
exec 9>"$HOME/.cache/animestream-installer.lock"
flock -n 9 || die 'Another installer is running'
root=$data/animestream-install
current=$root/current
launcher=$HOME/.local/bin/animestream
desktop=$data/applications/animestream.desktop
marker=animestream-linux-installer-v1
installed=false
[[ ! -L $root ]] || die "Refusing symlink installation: $root"
if [[ -e $root ]]; then
    [[ -f $root/.managed && ! -L $root/.managed && $(cat -- "$root/.managed") == "$marker" ]] || die "Unmanaged installation: $root"
    installed=true
fi
if [[ -e $launcher || -L $launcher ]]; then
    [[ -L $launcher && $(readlink -- "$launcher") == "$current/animestream" ]] || die "Launcher already exists: $launcher"
fi
[[ ! -L $desktop ]] || die "Desktop entry is a symlink: $desktop"
[[ ! -e $desktop || ( $installed == true && -f $desktop ) ]] || die "Desktop entry already exists: $desktop"
if [[ -z $action ]]; then
    { exec 8<>/dev/tty; } 2>/dev/null || die 'The menu needs a terminal. For automation, pass install, update, or uninstall.'
    installer_menu
    exec 8>&-
fi
refresh_menu() {
    if command -v update-desktop-database >/dev/null; then
        update-desktop-database "$data/applications" || echo 'Warning: desktop menu refresh failed.' >&2
    fi
}
if [[ $action == uninstall ]]; then
    if [[ $installed == false ]]; then echo 'animestream is not installed by this script.'; exit 0; fi
    rm -f -- "$launcher" "$desktop"
    rm -rf -- "$root"
    refresh_menu
    echo 'Uninstalled animestream. Settings and downloaded media were preserved.'
    exit 0
fi
[[ $action != update || $installed == true ]] || die 'Run install first'
[[ $action != install || $installed == false ]] || die 'Already installed; run update instead'
old_target=
if [[ $installed == true ]]; then
    [[ -L $current ]] || die 'Managed installation has no current release symlink'
    old_target=$(readlink -- "$current")
    [[ $old_target == release-* && $old_target != */* ]] || die 'Invalid current release target'
fi
echo 'Close animestream before replacing its files.'
temporary=$(mktemp -d)
generation= pending= desktop_pending= committed=false switching=false
had_launcher=false
[[ ! -L $launcher ]] || had_launcher=true
cleanup() {
    local status=$?
    trap - EXIT
    set +e
    if [[ $committed == false ]]; then
        if [[ $switching == true ]]; then
            if [[ -n $old_target ]]; then
                rm -f -- "$pending"
                ln -s -- "$old_target" "$pending" && mv -Tf -- "$pending" "$current"
            else
                rm -f -- "$current"
            fi
            [[ $had_launcher == true ]] || rm -f -- "$launcher"
        fi
        [[ -z $generation ]] || rm -rf -- "$generation"
        if [[ $installed == false && -f $root/.managed ]]; then
            rm -f -- "$root/.managed"
            rmdir -- "$root" 2>/dev/null
        fi
    fi
    [[ -z $pending ]] || rm -f -- "$pending"
    [[ -z $desktop_pending ]] || rm -f -- "$desktop_pending"
    rm -rf -- "$temporary"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
version='local bundle'
if [[ -z $bundle ]]; then
    [[ $(uname -m) == x86_64 ]] || die 'Published linux.zip is x64 only; use --bundle with a native build'
    for tool in curl jq; do command -v "$tool" >/dev/null || die "Install $tool first"; done
    endpoint=latest
    [[ -z $tag ]] || endpoint="tags/$(jq -rn --arg tag "$tag" '$tag|@uri')"
    curl --fail --location --silent --show-error --connect-timeout 30 --max-time 120 \
        "https://api.github.com/repos/frostnova721/animestream/releases/$endpoint" >"$temporary/release.json"
    url=$(jq -er '[.assets[] | select(.name == "linux.zip")] | if length == 1 then .[0].browser_download_url else error("Release must have one linux.zip asset") end' "$temporary/release.json")
    version=$(jq -er '.tag_name' "$temporary/release.json")
    printf 'Downloading %s...\n' "$version"
    curl --fail --location --show-error --connect-timeout 30 --max-time 1800 --proto '=https' --proto-redir '=https' \
        --output "$temporary/linux.zip" "$url"
    bundle=$temporary/linux.zip
fi
if [[ ! -d $bundle ]]; then
    [[ -f $bundle ]] || die "Bundle not found: $bundle"
    for tool in unzip zipinfo; do command -v "$tool" >/dev/null || die "Install unzip (including zipinfo) first"; done
    # Inspect paths and entry types before extraction; reject links and special files.
    zipinfo -1 "$bundle" >"$temporary/paths"
    while IFS= read -r entry; do
        case "/$entry/" in
            //*|*/../*|*\\*) die "Unsafe archive path: $entry" ;;
        esac
    done <"$temporary/paths"
    zipinfo -l "$bundle" >"$temporary/entries"
    if LC_ALL=C awk 'length($1) == 10 && $2 ~ /^[0-9]+\.[0-9]+$/ && $1 !~ /^[-d]/ {bad=1} END {exit !bad}' "$temporary/entries"; then
        die 'Archive contains links or special files'
    fi
    mkdir -- "$temporary/extracted"
    unzip -q "$bundle" -d "$temporary/extracted"
    bundle=$temporary/extracted
fi
[[ ! -d $bundle/bundle ]] || bundle=$bundle/bundle
for file in animestream lib/libflutter_linux_gtk.so data/icudtl.dat; do
    [[ -f $bundle/$file ]] || die "Incomplete Flutter bundle: missing $file"
done
[[ -d $bundle/data/flutter_assets ]] || die 'Missing data/flutter_assets'
header=$(od -An -tx1 -N6 -- "$bundle/animestream" | tr -d ' \n')
machine=$(od -An -tx1 -j18 -N2 -- "$bundle/animestream" | tr -d ' \n')
[[ $header == 7f454c460201 ]] || die 'Bundle must contain a 64-bit little-endian Linux executable'
case "$(uname -m):$machine" in
    x86_64:3e00|aarch64:b700|arm64:b700) ;;
    *) die 'Bundle architecture does not match this machine' ;;
esac
mkdir -p -- "$root" "${launcher%/*}" "${desktop%/*}"
printf '%s\n' "$marker" >"$root/.managed"
generation=$(mktemp -d "$root/release-XXXXXXXX")
cp -a -- "$bundle/." "$generation/"
chmod 755 -- "$generation/animestream"
printf '%s\n' "$version" >"$generation/version.txt"
desktop_value() {
    local value=$1
    value=${value//\\/\\\\}
    printf '%s' "$value"
}
command_path=$current/animestream
command_path=${command_path//\\/\\\\}
command_path=${command_path//\"/\\\"}
command_path=${command_path//\`/\\\`}
command_path=${command_path//\$/\\\$}
command_path=${command_path//%/%%}
icon=applications-multimedia
icon_relative=data/flutter_assets/lib/assets/icons/logo_foreground.png
[[ ! -f $generation/$icon_relative ]] || icon=$current/$icon_relative
desktop_pending=$(mktemp "${desktop}.XXXXXXXX")
{
    printf '[Desktop Entry]\nType=Application\nName=animestream\nComment=Stream and download anime\n'
    printf 'Exec="%s"\nIcon=%s\n' "$(desktop_value "$command_path")" "$(desktop_value "$icon")"
    printf 'Terminal=false\nCategories=AudioVideo;Video;\n'
} >"$desktop_pending"
chmod 644 -- "$desktop_pending"
[[ ! -e $root/current.new && ! -L $root/current.new ]] || die 'Unexpected current.new entry; inspect the installation directory'
pending=$root/current.new
ln -s -- "${generation##*/}" "$pending"
switching=true
mv -Tf -- "$pending" "$current"
[[ $had_launcher == true ]] || ln -s -- "$current/animestream" "$launcher"
mv -Tf -- "$desktop_pending" "$desktop"
committed=true
for previous in "$root"/release-*; do
    if [[ $previous != "$generation" && -d $previous && ! -L $previous ]]; then rm -rf -- "$previous"; fi
done
refresh_menu
printf 'Installed %s. Launch from your application menu or %s.\n' "$version" "$launcher"
case ":$PATH:" in
    *":${launcher%/*}:"*) ;;
    *) echo 'For terminal access, add to ~/.profile: export PATH="$HOME/.local/bin:$PATH"' ;;
esac
echo 'Requires compatible GTK 3, libsecret, WebKitGTK 4.1 and graphics libraries.'
