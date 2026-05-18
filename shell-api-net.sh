#!/bin/bash
###############################################################################
#
# Copyright (c) 2024-2025 Michel Mehl. All rights reserved.
#
# -----------------------------------------------------------------------------
#
# A shell API related to networking.
#
# -----------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
###############################################################################
__SHELL_API_NET_DIR__=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

source "${__SHELL_API_NET_DIR__}/shell-api-core.sh"

if _loaded "${BASH_SOURCE[0]}"  ; then
	return 0
fi

declare -A Net__servicePortMap
declare -A Net__ftpServersPackages

# Currently only this one is proposed
Net__ftpServersPackages="vsftpd"
# => check package for the following
# pure-ftpd 
# proftpd

# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
Net__servicePortMap["nfs"]=2049
Net__servicePortMap["ssh"]=22
Net__servicePortMap["ftp"]=21

:<<'EOF'
EOF
Net__checkOpenPort()
{
    local __in_service_name="$1"
    local __in_service_host="$2"
    local cmd
    cmd="${__SUDO__}nmap -p${Net__servicePortMap["${__in_service_name}"]} ${__in_service_host} | awk '/^${Net__servicePortMap["${__in_service_name}"]}/{FS=\" \";print \$2}'"
    _logf "COMMAND: $cmd"
    local pStatus="$(eval "$cmd")"
    Str__toLower pStatus
    # Filtered means that a firewall, filter, or other network obstacle is blocking the port so that Nmap cannot tell whether it is open or closed
    [ "$pStatus" = "open" ] || [ "$pStatus" = "filtered" ]
}


:<<'EOF'
Tells whether the passed argument looks like an HTTM URL, i.e.
of the basic form [http[s]://]xxx(.yyy)+

Safe characters	Alphanumeric [0-9a-zA-Z], special characters $-_.+!*'(),	No
Reserved characters	which are not allowed. / ? : @ = &	

@param [1] URL
@return true (0) when valid URL, false (1) when not, <0 on arg error

EOF

Net__isHTTP()
{
    local addr="$1"
    Str__toLower addr
    if [ $# -eq 1 ] ; then
         [[ "$addr" =~ ^https:\/\/([^\.^\/^?^:^@^=^&])+(\.([^\.^\/^?^:^@^=^&])+)+(\:[0-9]+)?\/?$ ]]
#         [[ "$addr" =~ ^(https?:\/\/)?([^\.^\/^?^:^@^=^&])+(\.([^\.^\/^?^:^@^=^&])+)+(\:[0-9]+)?\/?$ ]]
#        [[ "$addr" =~ ^(https?:\/\/)?(.*)$ ]]
    else
        _log_warn "${FUNCNAME[0]}: invalid argument count. Expected 1 argument."
        return -1
    fi
}


:<<'EOF'
Extracts only the host address from the HTTP URL
@param [1] HTTP URL
@param [2] reference to var for storing extracting hostname
EOF
Net__decodeHTTP()
{
    local url="$1"
    local -n out_host=$2
    local -n out_port=$3

    if ! Args__checkCount "${FUNCNAME[0]}" 3 "$#" ; then return -1 ; fi

    if ! Net__isHTTP "$url" ; then 
        _log_warn "${FUNCNAME[0]}: invalid HTTL URL '$url'."
        return 1
    fi

    Str__trim "$url" url
    Str__toTail url "//" last

    local remainder
    Str__split "$url" out_host ":" remainder 1 # when no ':' found, results only in host and remainder is empty
    if [ -z "$remainder" ] ; then
        Str__split "$url" out_host "/" remainder 1 # when no '/' found, results only in host and remainder is empty
    else
        Str__split "$remainder" out_port "/" remainder 1 # when no '/' found, results only in port and remainder is empty
    fi
    return 0
}


:<<'EOF'
Tells whether the passed argument looks like an URL, i.e.
of the basic form xxxxx://yyyyy
@param [1] URL
@return true (0) when valid URL, false (1) when not
EOF

Net__isURL()
{
    if [ $# -eq 1 ] ; then
        [[ "$1" =~ ^([a-zA-Z]*):\/\/(.*)$ ]]
    else
        _log_warn "${FUNCNAME[0]}: invalid argument count. Expected 1 argument."
        return -1
    fi
}

:<<'EOF'
Tells whether the passed argument looks like an IP4 address, i.e.
of the basic form <number>.<number>.<number>.<number>
@param [1] IP
@return true (0) when valid IP, false (1) when not, <0 on arg error
EOF

Net__isIP()
{
    if [ $# -eq 1 ] ; then
        [[ "$1" =~ ^([0-9]*)\.([0-9]*)\.([0-9]*)\.([0-9]*)$ ]]
    else
        #_log_warn "${FUNCNAME[0]}: invalid argument count. Expected 1 argument."
        return -1
    fi
}

:<<'EOF'
Tells whether the passed argument looks like a UNC path 
(universal naming convention) of the basic form //server/sharename[/path]
@param [1] URL
@return true (0) when valid UNC, false (1) when not, <0 on arg error
EOF

Net__isUNC()
{
    if [ $# -eq 1 ] ; then
        [[ "$1" =~ ^//([^/])+/([^/])+(/[^/]+)*$ ]]
    else
        _log_warn "${FUNCNAME[0]}: invalid argument count. Expected 1 argument."
        return -1
    fi
}

:<<'EOF'
Extracts hostname/ip, share from passed UNC
examples of valid netlogin
//192.168.0.40/MyShareName
@param [1] UNC
EOF
Net__decodeUNC()
{
    local unc="$1"
    local -n out_host=$2
    local -n out_share=$3

    if ! Args__checkCount "${FUNCNAME[0]}" 3 "$#" ; then return -1 ; fi

    if ! Net__isUNC "$unc" ; then 
        _log_warn "${FUNCNAME[0]}: invalid Netlogin '$unc'."
        return 1
    fi

    Str__trim "$unc" unc
    Str__toTail unc "//" last

    Str__split "$unc" out_host "/" out_share 1 # when no '/' found, result only in host and share is empty
    return 0
}

:<<'EOF'
Tells whether the passed argument looks like a login path 
of the basic form userlogin@host
@param [1] Netlogin
EOF

Net__isLogin()
{
    if [ $# -eq 1 ] ; then
        [[ "$1" =~ ^[^@^/]+@([^@^:^/])+(:[^@^:^/]+(/[^@^:^/]*)*+)?$ ]]
    else
        _log_warn "${FUNCNAME[0]}: invalid argument count. Expected 1 argument."
        return -1
    fi
}

:<<'EOF'
Extracts hostname/ip and user from passed netlogin <user>@<host>[:path]
examples of valid netlogin
albert@192.168.0.40
mikky@truesite.org:some/path

@param [1] Netlogin
EOF
Net__decodeLogin()
{
    local login="$1"
    local -n out_host=$2
    local -n out_user=$3
    local -n out_path=$4
    local remainder=""

    if ! Args__checkCount "${FUNCNAME[0]}" 4 "$#" ; then return -1 ; fi

    if ! Net__isLogin "$login" ; then 
        _log_warn "${FUNCNAME[0]}: invalid Netlogin '$login'."
        return 1
    fi

    Str__split "$login" out_user "@" remainder 0 # when no '@' found, result only in remainder and user is empty
    Str__split "$remainder" out_host ":" out_path 1 # when no ':' found, result only in host and path is empty


    return 0
}


:<<'EOF'
Tells whether the passed argument looks like a FTP URL, i.e.
of the basic form ftp://[user@]host
@param [1] URL
EOF

Net__isFTPURL()
{
    if [ $# -eq 1 ] ; then
       [[ "$1" =~ ^ftp://([^@]+@)?([^@^:^/])+(:[0-9]*)?(/)?$ ]] || [[ "$1" =~ ^curlftpfs#ftp://([^@]+@)?([^@^:^/])+(:[0-9]*)?(/)?$ ]]
    else
        _log_warn "${FUNCNAME[0]}: invalid argument count. Expected 1 argument."
        return -1
    fi
}

:<<'EOF'
Extracts hostname/ip, user, port number and pathfrom the passed SSH URL.
Expected URL format is the following:
ftp://[username@]<hostname or IP>

An output variable for the password is currently foreseen, but not filled.

@param [1] FTP URL
@param [2] out resulting hostname (or IP)
@param [3] out resulting user name
@param [4] out resulting password
EOF
# TODO TEST
Net__decodeFTPURL() 
{
    local url="$1"
    local -n out_host=$2
    local -n out_user=$3
    local -n out_passwd=$4
    local -n out_port=$5
    local remainder=""

    if ! Args__checkCount "${FUNCNAME[0]}" 5 "$#" ; then return -1 ; fi

    if ! Net__isFTPURL "$url" ; then 
        _log_warn "${FUNCNAME[0]}: invalid FTP URL '$url'."
        return 1
    fi

    Str__trim "$url" url
    Str__trimEnd "$url" url "/"
    
    Str__toTail url "ftp://" last

    Str__split "$url" out_user "@" remainder 0  # keep remainder and set user to "" if no '@' found
    Str__split "$remainder" out_host ":" out_port 1

    return 0
}


:<<'EOF'
Tells whether the passed argument looks like an NFS URL, i.e.
of the basic form nfs://host:share
@param [1] URL
EOF

Net__isNFSURL()
{
    if [ $# -eq 1 ] ; then
       [[ "$1" =~ ^nfs://([^:])+:(/[^/]+)+$ ]] 
    else
        _log_warn "${FUNCNAME[0]}: invalid argument count. Expected 1 argument."
        return -1
    fi
}

:<<'EOF'
Tells whether the passed argument looks like a regular NFS device, i.e.
of the basic form host:share
@param [1] URL
EOF

Net__isNFS()
{
    if [ $# -eq 1 ] ; then
       [[ "$1" =~ ^([^:])+:(/[^/]+)+$ ]] 
    else
        _log_warn "${FUNCNAME[0]}: invalid argument count. Expected 1 argument."
        return -1
    fi
}

:<<'EOF'
Extracts hostname and share from the passed URL

nfs://host:share

@param [1] NFS URL
@param [2] out resulting hostname (or IP)
@param [6] out resulting share path
EOF
# TODO TEST
Net__decodeNFSURL() 
{
    local url="$1"
    local -n out_host=$2
    local -n out_path=$3

    if ! Args__checkCount "${FUNCNAME[0]}" 3 "$#" ; then return -1 ; fi

    if ! Net__isNFSURL "$url" && ! Net__isNFS "$url"; then 
        _log_warn "${FUNCNAME[0]}: invalid NFS URL '$url'."
        return 1
    fi

    Str__trim "$url" url
    Str__trimEnd "$url" url "/"
    Str__toTail url "nfs://" last
    Str__split "$url" out_host ":" out_path 1  # keep host and set path to "" if no ':' found
   
    return 0
}





:<<'EOF'
Tells whether the passed argument looks like a SSH URL, i.e.
of the basic form ssh://[user@]host[:port][/path]
@param [1] URL
EOF

Net__isSSHURL()
{
    if [ $# -eq 1 ] ; then
       [[ "$1" =~ ^ssh://([^@]+@)?([^@^:])+(:[0-9]*)?(/[^/]+)*$ ]] 
    else
        _log_warn "${FUNCNAME[0]}: invalid argument count. Expected 1 argument."
        return -1
    fi
}

:<<'EOF'
Extracts hostname/ip, user, port number and pathfrom the passed SSH URL.
Expected URL format is the following:
ssh://[username@]<hostname or IP>[:<port number>][/path]

An output variable for the password is currently  foreseen, but not filled.

@param [1] SSH URL
@param [2] out resulting hostname (or IP)
@param [3] out resulting user name
@param [4] out resulting password
@param [5] out resulting port
@param [6] out resulting path
EOF
# TODO TEST
Net__decodeSSHURL() 
{
    local url="$1"
    local -n out_host=$2
    local -n out_user=$3
    local -n out_passwd=$4
    local -n out_port=$5
    local -n out_path=$6
    local remainder=""

    if ! Args__checkCount "${FUNCNAME[0]}" 6 "$#" ; then return -1 ; fi

    if ! Net__isSSHURL "$url" ; then 
        _log_warn "${FUNCNAME[0]}: invalid SSH URL '$url'."
        return 1
    fi

    Str__trim "$url" url
    Str__trimEnd "$url" url "/"
    
    Str__toTail url "ssh://" last

    Str__split "$url" out_user "@" remainder 0  # keep remainder and set user to "" if no '@' found
    if Str__split "$remainder" out_host ":" remainder 0 ; then  # keep remainder and set host to "" if no ':' found, host yet to be extracted
        # host + port case
        Str__split "$remainder" out_port "/" out_path 1 # keep out_port and set path to "" if no '/' found
    else
        # host + no port case
        Str__split "$remainder" out_host "/" out_path 1 # keep out_host and set path to "" if no '/' found
    fi
   
    return 0
}



:<<'EOF'
Tells whether the passed argument looks like a SMB URL, i.e.
of the basic form smb://yyyyy
@param [1] URL
EOF

Net__isSMBURL()
{
    if [ $# -eq 1 ] ; then
        [[ "$1" =~ ^smb:\/\/([^@]+@)?([^@^:])+(/[^/]+)*$ ]]
    else
        _log_warn "${FUNCNAME[0]}: invalid argument count. Expected 1 argument."
        return -1
    fi
}


:<<'EOF'
Extracts hostname/ip, user and share (shared folder name) from the passed URL.
Expected URL format is the following:
smb://<hostname or IP>[/<user>[:password][/<share>]]
examples of valid URL
smb://192.168.0.40/MyDataShare
smb://192.168.0.40/

@param [1] SAMBA URL
EOF

Net__decodeSMBURL()
{
    local url="$1"
    local -n out_host=$2
    local -n out_user=$3
    local -n out_passwd=$4
    local -n out_share=$5

    if ! Args__checkCount "${FUNCNAME[0]}" 5 "$#" ; then return -1 ; fi

    if ! Net__isSMBURL "$url" ; then 
        _log_warn "${FUNCNAME[0]}: invalid SMB URL '$url'."
        return 1
    fi

    Str__trim "$url" url
    Str__trimEnd "$url" url "/"
    Str__toTail url "smb://" last

    if Str__split "$url" out_user "@" remainder 0  ; then # keep remainder and set user to "" if no '@' found
        Str__split "$out_user" out_user ":" out_passwd 1   # set passwd to "" if no separator found
        Str__split "$remainder" out_host "/" out_share 1 
    else
        Str__split "$url" out_host "/" out_share 1 # when no '/' found, result only in host and share is empty
    fi

    return 0
}

Net__getHostIP()
{
    local -n out_hostIP=$1
    read out_hostIP< <(hostname -I | awk '{print $1}')
}

Net__getLocalHostIP()
{
    local -n out_hostIP=$1
    read out_hostIP< <(hostname -I | awk '{print $1}')
}

Net__getLocalHostname()
{
    local -n out_hostname=$1
    read out_hostname< <(hostname)
}


:<<'EOF'
Retrieves the hostname from the passed IP.
This function executes 2 subshells , one for nsloopkup, another for awk. 

@param [1] IP address
@param [2] out hostname resulting hostname, which is param 1 if it was actually not a valid IP address
EOF

Net__getHostname()
{
    local arg="$1"
    local -n out_hostname=$2
    if ! Args__checkCount "${FUNCNAME[0]}" 2 "$#" ; then return -1 ; fi

    if Net__isIP "$arg" ; then
            # try to resolve hostname
            local lookupres=$(nslookup "${arg}")
            if [ $? -eq 0 ] ; then
                    out_hostname=$(echo "$lookupres"|awk -F'=' 'BEGIN { res=1 } { if (substr($1,length($1)-4,4)=="name") {print $2; res=0; exit 0}} END { exit res}')
                    if [ $? -eq 0 ] ; then
                            Str__trim "$out_hostname" out_hostname
                            Str__trimEnd "$out_hostname" out_hostname "."
                    else
                        out_hostname="$arg"
                    fi
            else
                out_hostname="$arg"
            fi
    else
        out_hostname="$arg"
    fi    
    return 0
}

:<<'EOF'
Converts an IP to the matching hostname

@param [1] IP address
@param [2] out hostname resulting hostname, which is param 1 if it was actually not a valid IP address
EOF

Net__IP2Name()
{
    local in_host="$1"
    local -n out_host="$2"

    if ! Args__checkCount "${FUNCNAME[0]}" 2 "$#" ; then return -1 ; fi

    local hostname=""
    Net__getHostname "$in_host" hostname
    #_log_dbg "Net__IP2Name for $in_host hostname=$hostname"
    if [ "$in_host" != "$hostname" ] ; then
            out_host="$hostname"
    fi    
}

Net__resolve()
{
     local __in_addr="$1"   
     local -n __out_ip_addr=$2
     local -n __out_hostname_addr=$3

     if Net__isIP "${__in_addr}" ; then
        __out_ip_addr="${__in_addr}"

        local __resolve_hostname
        Net__IP2Name "${__in_addr}" __resolve_hostname
        __out_hostname_addr="${__resolve_hostname}"
     else
        __out_hostname_addr="${__in_addr}"
        local __ip
        local __resRet
        __ip="$(host "${__in_addr}")"
        __resRet=$?
        __out_ip_addr="$(echo "$__ip"|head -n1|awk -F' ' '{print $NF}')"
        if ! Net__isIP "${__out_ip_addr}" ; then
                _log_warn "Failed to retrieve an IP address from hostname '${__in_addr}'. Original output: ${__ip}."
                __out_ip_addr="${__in_addr}"
                return 1
        fi
     fi
    if [ "$__out_ip_addr" = "127.0.1.1" ] ; then
        local allIPs="$(hostname -I)"
        __out_ip_addr="${allIPs%% *}"
    fi
    return 0
}

:<<'EOF'
Download a file from a given URL using wget

@param [1] URL
@returns 0 on success, 2 if site is not reachable, 1 if site is reachable but download failed somehow.
EOF

Net__download()
{
    local url="$1"
    if wget --spider -T 4 -t 1 "$url" &>/dev/null; then # try once to reach server with a timeout of 4s
        if ! wget -nc --quiet "$url" ; then # -nc no clobber: do not allow download several times the same files with giving different names. 
            _log_err "${FUNCNAME[0]}: failed to download $pkgfile from URL $url"
            return 1
        else
            return 0
        fi
    else
        return 2
    fi
}

:<<'EOF' 
Tells whether the passed argument string is a valid known cloud service driver (not an URL). 
e.g. google-drive-ocamlfuse
EOF

Net__isCloudDevice()
{
    local cloudService="$1"
    Str__toLower cloudService
    case "$cloudService" in
        "google-drive-ocamlfuse") return 0;;
        *) return 1;;
    esac
    return 1
}

Net__getCloudURLFromDevice()
{
    local cloudService="$1"
    local -n __out_cloudURL=$2
    Str__toLower cloudService
    case "$cloudService" in
        "google-drive-ocamlfuse") 
            __out_cloudURL="https://drive.google.com"
            return 0
            ;;
        *) return 1;;
    esac
    return 1
}


Net__isNetworkURL()
{
    Net__isUNC "$1" || Net__isLogin "$1" || Net__isSMBURL "$1" || Net__isSSHURL "$1" || Net__isFTPURL "$1" || Net__isNFSURL "$1"
}