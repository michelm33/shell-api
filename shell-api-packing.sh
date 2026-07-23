#!/bin/bash
###############################################################################
# HUMAN-READABLE "BSA BASH SHELL API" and genapp bash app generator
# 
# Copyright (c) 2024-2026 Michel Mehl.
# All rights reserved. 
# Tous droits réservés (France).
# 
# License terms written down in file LICENSE.txt
# Les termes de la licence sont détaillés dans le fichier LICENSE.txt
# 
# Release file path: shell-api-packing.sh
# Release file date: 2026-07-23 13:37
# App version: 1.1.0
# App source revision: 97
# App source signature: e20eb96b3d4e6835befb66ce8f066b37209f14602974b26a9ca3fd01599ac513
# Source file last modification: 2026-06-07 23:01:10.265430016 +0200
#
# This header was generated. Do not modify.
#
# -----------------------------------------------------------------------------
#
# A shell API intended for managing of package installation.
#
# -----------------------------------------------------------------------------
# 
# Report bugs and suggestions: 
#     assistance@slashetc.fr
# 
# Specific or corporate requirements or extensions: 
#     info@slashetc.fr
# 
# The author is overall not required to provide maintenance or support 
# outside specific commercial terms agreed.
# 
###############################################################################
__SHELL_API_PACKING_DIR__=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

source "${__SHELL_API_PACKING_DIR__}/shell-api-core.sh"

declare -A Pkg__dpkgNameVariantsMap
Pkg__dpkgNameVariantsMap["libfuse2"]="libfuse2 libfuse2t64"
Pkg__dpkgNameVariantsMap["adb"]="adb google-android-platform-tools-installer"


if _loaded "${BASH_SOURCE[0]}"  ; then
	return 0
fi

:<<'EOF'
Installs the named packages according to the specified method. The URL can contain 
the following placeholders which will be replaced with actual values:
%%name%%:       package name as specified by 1st argument
%%version%%:    version as specified by 2nd argument
%%arch%%:       machine archicture as return by 'uname -m'. amd64 is returned for x86_64
%%distroname%%: linux distribution name as returned by 'lsb_release -is'
%%distrover%%:  distribution version

@param [1] package name
@param [2] package version. 
@param [3] installation method (apt, gem, snap, dpkg, http folder,...)
@param [4] if necessary, URL or filename
@param [5] options
@param [6] an executable condition to fulfill for performing the installation
@param [7] an executable post installation condition, which result has to be returned by this function.
@example Pkg__install vera https://launchpad.net/veracrypt/trunk/1.26.14/+download/ 
EOF

Pkg__install()
{
    local pkg="$1"
    local alternatives=()
    local ver="$2"
    local meth="$3"
    local url=""
    local options=""
    local testInstallCond=""
    local postInstallCond=""
    local doRefresh=1
    if [ $# -ge 4 ] ; then  
        url="$4"
    fi
    if [ $# -ge 5 ] ; then  
        if [ ! -z "$5" ] ; then
            options="$5"
            if Str__contains "$options" "--reinstall" ; then
                doRefresh=0
            fi
        fi
    fi    
    if [ $# -ge 6 ] ; then  
        testInstallCond="$6"
    fi       
    if [ $# -ge 7 ] ; then  
        postInstallCond="$7"
    fi       
    local ret=0

    #if [ ! -z "$ver" ] && [ "$meth" != "dpkg" ]; then
    #    _log_warn "${FUNCNAME[0]}: installation of specific versions are not handled yet. Version ignored, default installation is proceeding.."
    #fi
:<<'EOF'
    Str__split "$1" pkg "|" alternatives 1 # when no '`' found, results only in pkg and alternatives is empty
    Str__trim "$pkg" pkg
    Str__trim "$alternatives" alternatives
EOF

    local alternativesString=""
    local expectedProgForAlternatives=""
    Str__split "$1" expectedProgForAlternatives "@" alternativesString 0
    readarray -t -d'|' alternatives <<< "$alternativesString"    
    #_log_dbg "'$expectedProgForAlternatives' '$alternativesString'"

    _log_dbg "Pkg__install '${pkg}' (alternatives:'${alternatives[@]} ') '$meth' options:'$options' url:'$url'"

    case "$meth" in
        apt)
            if [ ! -z "$expectedProgForAlternatives" ] ; then
                if which "$expectedProgForAlternatives" &>/dev/null ; then return 0; fi
            fi
            local alternCnt=0
            while [ $alternCnt -lt ${#alternatives[@]} ] ; do
                local aPkg="${alternatives[$alternCnt]}"
                Str__trimEnd "$aPkg" aPkg
                if DPKG__exists "${aPkg}" ; then
                     #_log_dbg "Package exists! '${aPkg}'"
                    if APT__isInstalled "${aPkg}" &>/dev/null ; then
                        return 0
                    else
                        #_log_dbg "Package is not installed ! '${aPkg}'"
                        if APT__install "${aPkg}" "$options" ; then
                            return 0
                        fi
                    fi                    
                fi
                alternCnt=$(($alternCnt + 1))
            done
            # We should not reach this point
            return 1
            ;;
        opam)
            OPAM__install "$pkg" "$options"
            return $?
            ;;
        snap)
            SNAP__install "$pkg"
            return $?
            ;;
        gem)
            GEM__install "$pkg"
            return $?
            ;;
        sh) 
            local testInstallRes=0
            #_log_dbg "evaluating '$testInstallCond'"
            if [ ! -z "$testInstallCond" ]  ; then
                $testInstallCond &>/dev/null # use 2> for debug
                testInstallRes=$?
            fi
            if [ $testInstallRes -ne 0 ] ; then
                # installation by shell
                local pkgfile
                if Str__startsWith "$url" "http"; then
                    #_log_dbg "Net__download '$url'"
                    Net__download "$url"
                    if [ $? -ne 0 ] ; then
                        return 1
                    fi
                    pkgfile="$(realpath $(basename "$url"))"
                    chmod 755 "$pkgfile"
                else
                    pkgfile="$url"
                fi
                _log_dbg "evaluating '"$pkgfile" $options'"
                eval $pkgfile $options
                if [ $? -eq 0 ] && [ ! -z "$postInstallCond" ] ; then
                    eval "$postInstallCond"
                    return $?                
                else
                    _log_err "installation command '$pkgfile $options' failed"
                fi
            else
                _log_warn "$pkg is already installed."
                return 0
            fi
            ;;
        dpkg)
            if [ $doRefresh -eq 0 ] && DPKG__isInstalled "$pkg" ; then                
                _log "Purging $pkgfile  installation"
                ${__SUDO__}dpkg -P  --force-remove-reinstreq "$pkg" 2>>"${__LOG_ERR_FILE__}" # --force-all #${__SUDO__}dpkg --remove --force-remove-reinstreq "$pkg" 
            fi

            if DPKG__isInstalled "$pkg"; then
                _log_dbg "Debian package $pkg already installed"
                return 0
            fi

            if Str__startsWith "$url" "http"; then
                local distrover=""
                Env__distrover 2 distrover                
                local distroname="$(Env__distroname)"
                local distrover_major=""
                Env__distrover 1 distrover_major

                local distrover_minor=""
                if [ "$distroname" == "Ubuntu" ] ; then
                    case "${distrover_major}" in
                        26) distrover="${distrover_major}.14";;
                        *) distrover="${distrover_major}.04";;
                    esac
                fi
                Str__replace url "%%name%%" "$pkg"
                Str__replace url "%%version%%" "$ver"
                Str__replace url "%%arch%%" "$(Env__arch)"
                Str__replace url "%%distroname%%" "$distroname"
                Str__replace url "%%distrover%%" "${distrover}"
                Str__replace url "%%distrovermajor%%" "${distrover_major}"
                Str__replace url "%%distroverminor%%" "${distrover_minor}"
                local pkgfile="$(basename "$url")"
                _log_status high "Downloading $pkgfile from '$url' ..."
                if Net__download "$url" ; then
                    _log_status_end ok
                    ${__SUDO__}dpkg -i "$pkgfile" 2>>"${__LOG_ERR_FILE__}"  >>"${__LOG_FILE__}"
                    if [ $? -ne 0 ] ; then
                        _log_err "Failed to install $pkgfile. Further details in log file ${__LOG_ERR_FILE__}."
                        return 1
                    else
                        rm -f "$pkgfile"
                    fi
                    return 0
                else
                    _log_status_end fail
                    #_log_err "Failed to download $pkgfile from '$url'. The URL is probably incorrect or ressource is inexistent."
                    return 1
                fi
            else
                _log_err "unrecognized URL $url"
                return -2
            fi
            ;;
        *)
	        _log_err "${FUNCNAME[0]}: invalid or unsupported package tool $meth"
            return -1
            ;;
    esac
    return -1
}

:<<'EOF'
Checks whether a debian package passed as argument is installed.
@param [1] debian package name
This function takes into consideration different possible variant names 
of the package depending on the linux distribution and its version.
EOF

DPKG__isInstalled() { 
    local res=0
    local variants=(${Pkg__dpkgNameVariantsMap["$1"]})
    if [ ${#variants[@]} -eq 0 ] ; then
        variants+=("$1")
    fi

    local variant
    for variant in "${variants[@]}" ; do
        if  ! dpkg-query -l "${variant}" &>/dev/null || [ $(dpkg-query -W -f='${db:Status-Abbrev}' "${variant}") != "ii" ]  ; then
            res=1
        else
            res=0
        fi

        if [ $res -eq 0 ] ; then
            break;
        fi
    done

    return $res
}


:<<'EOF'
Checks whether the passed package name even exists for installation.
@param [1] apt/dpgk package name
EOF

DPKG__exists() { 
    local res=0

    pushd /etc/apt &>/dev/null
    local retVal=""
    retVal="$(apt-cache search --names-only "$1" 2>/dev/null)"
    if [ $? -ne 0 ] || [ -z "${retVal}" ] ; then
        # By test it happened that 0 was returned and empty string for non-available package e.g. tzdata-legacy
        res=1
    else
        res=0
    fi
    popd &>/dev/null

    return $res
}

:<<'EOF'
Checks whether a system APT package passed as argument is installed.
@param [1] apt package name
EOF

APT__isInstalled() { 
    local res=0

    if pushd /etc/apt &>/dev/null && ! DPKG__isInstalled "$1" &>/dev/null  ; then
        res=1
    else
        res=0
    fi
    popd &>/dev/null

    return $res
}

:<<'EOF'
Installs the list of APT packages given as argument.
@param [1] list of space-separated package names in a string.
@param [2] additional install options
EOF

APT__install() {
    # Because of the failure when run from inside a SSHFS-mounted filesystem (chdir (2: No such file or directory))
    local cwd="$(pwd)"
    local ret=0
    local pkg=""
    local packages=($1)
    local options="$2"
    cd /etc/apt

    local doRefresh=1

    if Str__contains "$options" "--reinstall" ; then
        doRefresh=0
        ${__SUDO__}apt-get update
    fi

    for pkg in "${packages[@]}"
    do
        #_log_dbg "APT install PACKAGE '$pkg' of '${packages[@]}'"
        if ! APT__isInstalled "$pkg" &>/dev/null || [ $doRefresh -eq 0 ]; then
            _log_status high "Installing package $pkg (APT)"             

            DEBIAN_FRONTEND=noninteractive ${__SUDO__}apt -q --yes install $options "$pkg" 2>>"${__LOG_ERR_FILE__}"  >>"${__LOG_FILE__}"
            #${__SUDO__}apt --yes install $options "$pkg" 2>>"${__LOG_ERR_FILE__}"  >>"${__LOG_FILE__}"
            if [ $? -eq 0 ] ; then
                _log_status_end ok
            else
                _log_status_end fail
                _log_status high "Installation failed. Retrying after an apt update"
                ${__SUDO__}apt-get update 2>>"${__LOG_ERR_FILE__}"  >>"${__LOG_FILE__}"
                if [ $? -eq 0 ] ; then
                    _log_status_end ok
                    _log_status high "Installing package $pkg (APT)"             
                    DEBIAN_FRONTEND=noninteractive  ${__SUDO__}apt -q --yes install $options "$pkg" 2>>"${__LOG_ERR_FILE__}"  >>"${__LOG_FILE__}"
                    if [ $? -eq 0 ] ; then
                        _log_status_end ok
                    else
                        _log_status_end fail
                    fi
                else
                    _log_status_end fail
                fi
            fi

            if ! APT__isInstalled "$pkg" &> /dev/null ; then
                _log_warn "failed to install package $pkg (APT). Further details in log file ${__LOG_ERR_FILE__}. You can also check output using 'dpkg-query -l $pkg'"
                ret=1
            else
                _log_dbg "Package $pkg successfully installed (APT)"
            fi
        else
            _log_dbg "Package $pkg already installed (APT)"
        fi
    done

    cd "$cwd"
    return $ret
}

:<<'EOF'
Installs the list of APT packages given as argument.
@param [1] list of space-separated package names in a string.
@param [2] additional install options
EOF

APT__distant_install() {
    # Because of the failure when run from inside a SSHFS-mounted filesystem (chdir (2: No such file or directory))
    local ret=0
    local pkg=""
    local packages=($1)
    local options="$2"
    local login="$3"
    local host="$4"
    local reinstallOption=""
:<<'EOF'
    # not implemented yet for remote install
    #local doRefresh=1 
    if Str__contains "$options" "--reinstall" ; then
        doRefresh=0
        ${__SUDO__}apt-get update
    fi
EOF
    for pkg in "${packages[@]}"
    do
        local __apt_cmd="$(cat << EOF 
ssh ${login}@${host} '(dpkg-query -l "${pkg}" &>/dev/null && ! test -z "\$(dpkg-query -W -f='\${db:Status-Abbrev}' "${pkg}"|grep -E ^ii)") || sudo DEBIAN_FRONTEND="noninteractive" -S apt install ${pkg}'
EOF
)"
        _logf "APT COMMAND: '$__apt_cmd'"
        eval "${__apt_cmd}" #2>>"${__LOG_ERR_FILE__}"

:<<'EOF'
        local __apt_cmd="plink -X ${login}@${host} 'dpkg-query -l \"${pkg}\" &>/dev/null && [[ \$(dpkg-query -W -f='\''\${db:Status-Abbrev}'\'' \"${pkg}\" 2>/dev/null) =~ ^ii ]] || sudo -S DEBIAN_FRONTEND=\"noninteractive\" apt install ${pkg} -y || echo NOPE' >> \"${__LOG_FILE__}\""
        _logf "COMMAND: '$__apt_cmd'"
        local testInstalled
        testInstalled="$(eval "$__apt_cmd")"
        local res=$?
        Str__trim "$testInstalled" testInstalled
        #_log_vars testInstalled
        if Str__endsWith "$testInstalled" "NOPE" || [ $res -ne 0 ]; then
EOF
        if [ $? -ne 0 ] ; then
                ret=1
                continue
                _log_warn "failed to install package $pkg (APT) on $login@$host."
        else
                _log_dbg "Package $pkg successfully installed  on $login@$host (APT)"
        fi
    done

    return $ret
}



:<<'EOF'
Tells whether the passed OPAM package is installed.
@param [1] package name
@returns 0 if installed, another value otherwise.
EOF

OPAM__isInstalled() {
    local listedItem=$(opam list -s -i --columns=name "$1" 2>/dev/null)
    [ ! -z "$listedItem" ]
}


:<<'EOF'
Installs the list of snap packages given as argument.
@param [1] array of snap package names
EOF

OPAM__install()
{
    local res=0
    local pkg=""
    local packages=($1)
    local options="$2"

    for pkg in "${packages[@]}"
    do
        if  OPAM__isInstalled $pkg 2> /dev/null; then
            _log "Package $pkg (opam) already installed"
        else
            #since v2.1 depext is provided for backward compatibility
            #_log_dbg "loading external deps OPAM PKG : '$pkg'"
            #${__SUDO__}opam depext "$pkg"
            _log "Installing OPAM '$pkg' with options '$options' ..."
            opam install "$pkg" $options  2>>"${__LOG_ERR_FILE__}" >>"${__LOG_FILE__}"
            if [ $? -ne 0 ] ; then
                _log_warn "failed to install package $pkg (opam). Further details in log file ${__LOG_ERR_FILE__}."
                res=1
            fi
        fi
    done
    return $res
}



:<<'EOF'
Tells whether the passed SNAP package is installed.
@param [1] package name
EOF

SNAP__isInstalled() {
    snap list "$1" &> /dev/null
}

:<<'EOF'
Installs the list of snap packages given as argument.
@param [1] array of snap package names
EOF

SNAP__install()
{
    local res=0
    local pkg=""
    for pkg in "$@"
    do
        if  SNAP__isInstalled $pkg; then
            _log_dbg "Package $pkg (snap) already installed"
        else
            _log "Installing SNAP package '$pkg' ..."

            ${__SUDO__}snap install "$pkg" 2>>"${__LOG_ERR_FILE__}" >>"${__LOG_FILE__}"
            if [ $? -ne 0 ] ; then
                _log_warn "failed to install package $pkg (snap). Further details in log file ${__LOG_ERR_FILE__}."
                res=1
            fi
        fi
    done
    return $res
}

:<<'EOF'
Tells whether the passed GEM package is installed.
@param [1] package name
EOF

GEM__isInstalled() {
    gem list "$1" -i &> /dev/null
}

:<<'EOF'
Installs the list of GEM packages given as argument.
@param [1] array of package names
EOF

GEM__install()
{
    local res=0
    local pkg=""
    for pkg in "$@"
    do
        if  GEM__isInstalled $pkg; then
            _log_dbg "Package $pkg (gem) already installed"
        else
            _log "Installing GEM package '$pkg' ..."
            ${__SUDO__}gem install "$pkg" 2>>"${__LOG_ERR_FILE__}" >>"${__LOG_FILE__}"
            if [ $? -ne 0 ] ; then
                _log_warn "Failed to install package $pkg (gem). Further details in log file ${__LOG_ERR_FILE__}."
                res=1
            fi
        fi
    done
    return $res
}
