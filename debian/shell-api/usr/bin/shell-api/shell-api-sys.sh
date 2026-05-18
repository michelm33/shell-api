#!/bin/bash
###############################################################################
#
# Copyright (c) 2024 Michel Mehl. All rights reserved.
#
# -----------------------------------------------------------------------------
#
# A shell API related to low-level system functions.
#
# -----------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
###############################################################################
__SHELL_API_SYS_DIR__=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

source "${__SHELL_API_SYS_DIR__}/shell-api-core.sh"

if _loaded "${BASH_SOURCE[0]}"  ; then
	return 0
fi

:<<'EOF'
Return size of the passed file
@param[1] file path
@param[2] ref to variable where to store size
EOF

File__getSize()
{
    if ! Args__checkCount ${FUNCNAME[0]} 2 "$#" "Usage: <filepath> <ref to var for storing size>"; then 
        return 1
    fi

    local filePath="$1"
    local -n __out_size="$2"
    local ret
    read __out_size < <(stat -c "%s" "$filePath") # &>/dev/null)
    ret=$?
    if [ $ret -ne 0 ] ; then
        _log_dbg "${FUNCNAME[0]}: '${__out_size}'"
        _log_warn "${FUNCNAME[0]}: invalid file path $filePath."
    fi
    return $ret
}


:<<'EOF'
Returns PID of current running script
Beware not to call this from a subshell (e.g with notation $(...)), otherwise
the PID of the temporary subshell is returned!
@param [1] reference of the variable where to store the PID
EOF

Sys__getPID()
{
    if [ $# -eq 1 ] ; then
        local -n out_pid=$1
        out_pid=$$
    else
        _log_warn "${FUNCNAME[0]}: missing variable name reference argument."
    fi
}

:<<'EOF'
Waits for the process of the given PID to end. If input PID is 0, nothing is done.
@param [1] ref to the variable containing the PID. If process ended, variable value is reset to 0
@returns return value of low level 'wait', that is the exit code of the process normally.
If input PID is 0, nothing is done and 0 is returned.
EOF

Sys__wait()
{
    if ! Args__checkCount ${FUNCNAME[0]} 1 "$#" "Usage: <ref to var containing PID>"; then 
        return 1
    fi
    local -n __out_pid=$1

    if [ $__out_pid -eq 0 ] ; then
        return 0
    fi

    local ret
    wait $__out_pid
    ret=$?
    __out_pid=0
    return $ret
}


:<<'EOF'
Spawns a process in background and stores the PID in passed var.
@param [1] ref to the variable that will contain the PID of launched process. 
@param [2] the command to launch
@returns return 0 on success only.
EOF

Sys__spawn()
{
    if ! Args__checkMinCount ${FUNCNAME[0]} 2 "$#" "Usage: <ref to var containing PID> <command> <args>"; then 
        return 1
    fi
    local -n __out_pid=$1
    shift

#echo "Sys__spawn avec args '$@'"
    eval "$@" &
    __out_pid=$!
    return 0
}

Sys__gspawn_init()
{
    Sys__global_pid_file="$1/.sys__global_gids.txt"
}

:<<'EOF'
Spawns a process in background and stores the PID in the global array 'Sys__global_pid'
@param [1] the command to launch
@returns return 0 on success only.
EOF
Sys__global_pid_file=".sys__global_gids"

Sys__gspawn()
{
    if ! Args__checkMinCount ${FUNCNAME[0]} 1 "$#" "Usage: <command> <args>"; then 
        return 1
    fi
    local pid
	Sys__spawn pid "$@"
    if [ $? -eq 0 ] ; then
        #Sys__global_pid+=($pid)
        Sys__addGlobalPid "$pid"
        return 0
    else 
        return 1
    fi
}

:<<'EOF'
Waits for all processes which pid is stored in the global array 'Sys__global_pid' to wait, 
and the clear that arraY.
EOF

Sys__gwait()
{
	#if [ ${#Sys__global_pid[@]} -gt 0 ] ; then
        _logf "${FUNCNAME[0]}: WAIING FOR PROCESSES ${Sys__global_pid[@]}"

        exec 9> /var/lock/sys__global_gids.lock
        if ! flock -x -w 10 9; then
            return 1
        fi
        local configPath="${Sys__global_pid_file}"
        if [ -f "$configPath" ] ;  then
            local globalPids
            read globalPids< <(cat "$configPath")
            echo > "$configPath"
            Str__trim "$globalPids" globalPids 
            #_log "Sys__gwait: waiting for processes ${globalPids}"
        fi
        flock -u 9
        exec 9>&-

        if [ ! -z "${globalPids}" ] ; then
            wait ${globalPids}
            lastStatus=$?
        fi
        _logf "${FUNCNAME[0]}: END WAIING"
        return $lastStatus
        #Sys__global_pid=()
    #fi
}


Sys__addGlobalPid()
{
    local pid="$1"
    local configPath="${Sys__global_pid_file}"
    #_log "Sys__addGlobalPid adding pid '$pid' to file '$configPath'"
   (
    flock -w 10 9 || return 1
    echo -n "${pid} " >> "$configPath"
    sync "$configPath"
    ) 9>/var/lock/sys__global_gids.lock
}

Sys__pool_init()
{
    local name="$2"
    local size=$3
    local -n __inout_pool=$1

    __inout_pool[0]="$name"
    __inout_pool[1]=$size

    Sys__pool_reset __inout_pool

    #_log "${FUNCNAME[0]}: init done for ${__inout_pool[0]} of size ${__inout_pool[1]}"
}

Sys__pool_reset()
{
    local -n __inout_pool_reset=$1
    local size=${__inout_pool_reset[1]}
 
    if [ -z "$size" ] ; then
        _log_err "${FUNCNAME[0]}: Invalid pool passed. No pool size value stored in \${pool[1]}."
        return 1
    fi
    size=$(($size+2))
    local c=2
    while [ $c -lt $size ] ; do
        __inout_pool_reset[c]="x"
        c=$(($c+1))
    done

    #_log "${FUNCNAME[0]}: reset done for ${__inout_pool_reset[0]} of size ${__inout_pool_reset[1]}"
}

Sys__pool_pid_list()
{
    local -n __in_pool_list=$1
    local -n __out_pidlist=$2
    local size=${__in_pool_list[1]}
 
    if [ -z "$size" ] ; then
        _log_err "${FUNCNAME[0]}: Invalid pool passed. No pool size value stored in \${pool[1]}."
        return 1
    fi

    size=$(($size+2)) # 2 first are name and size
    local c=2
    while [ $c -lt $size ] ; do
        # Take the first free
        if [ ${__in_pool_list[$c]} != "x" ] ; then
            __out_pidlist+=(${__in_pool_list[$c]})
        fi
        c=$(($c+1))
    done
    return 0
}

Sys__pool_pid_print()
{
    local -n __inout_pool_print=$1
    local message="$2"
    local pidlist=()
    Sys__pool_pid_list __inout_pool_print pidlist
    echo "$message: ${pidlist[@]}"
}

Sys__pool_spawn()
{
#    echo "START ++ Sys__pool_spawn avec args $# '$*'"

    local -n __inout_pool_spawn=$1
    local size=${__inout_pool_spawn[1]}
    shift # Shif to the command to launch
 
    if [ -z "$size" ] ; then
        _log_err "${FUNCNAME[0]}: Invalid pool passed. No pool size value stored in \${pool[1]}."
        return 1
    fi
    
    size=$(($size+2)) # 2 first are name and size
    local c=2
    while [ $c -lt $size ] ; do
        # Take the first free
        if [ ${__inout_pool_spawn[$c]} == "x" ] ; then
            local pid=0

#echo "Sys__pool_spawn avec args '$@'"

            Sys__spawn pid "$@"
            if [ $pid -ne 0 ] ; then
                #_log "${FUNCNAME[0]}: launched $pid on slot $c"
                __inout_pool_spawn[$c]=$pid
                return 0
            fi
        fi
        c=$(($c+1))
    done

    Sys__pool_waitall __inout_pool_spawn

    # Take the first freed
    local c=2
    while [ $c -lt $size ] ; do
        if [ ${__inout_pool_spawn[$c]} == "x" ] ; then
            local pid=0
            Sys__spawn pid "$@"
            if [ $pid -ne 0 ] ; then
                #_log "${FUNCNAME[0]}: launched $pid on slot $c after a waitall"
                __inout_pool_spawn[$c]=$pid
                return 0
            fi
        fi
        c=$(($c+1))
    done

    _log_warn "${FUNCNAME[0]}: ${__inout_pool_spawn[0]} of size ${__inout_pool_spawn[1]} is full. waiting for current pool to finish"

    return 1
}

Sys__pool_waitall()
{
    local -n __inout_pool_waitall=$1
    local pidlist=()
    local lastStatus=0
    Sys__pool_pid_list __inout_pool_waitall pidlist

    #_log "${FUNCNAME[0]}: wait for pid : ${pidlist[@]}"

    wait ${pidlist[@]}
    lastStatus=$?
    Sys__pool_reset __inout_pool_waitall
    return $lastStatus
}

Sys__isAlive()
{
    kill -s 0 "$1" 2>/dev/null
}

Sys__sweep()
{
    if ! Args__checkCount ${FUNCNAME[0]} 2 "$#" "Usage: <proc name> <argument filter>"; then 
        return 1
    fi

    local pids
    pids=$(ps -ha -o pid,comm,cmd| awk -F' ' -v procname="$1" -v argfilter="$2" '{
        if ($2 == procname)
        {
            #print "OK",$2,procname, argfilter,$3
            idx=index($0,argfilter)
            if (idx > 0)
            {
                print $1
            }
        }
    }')
    local pidsA=($pids)
    #_log "Sys__sweep: '$pids'"
    if [ ${#pidsA[@]} -gt 0 ] ; then
        #echo kill ${pidsA[@]}
        kill -15 ${pidsA[@]}
    #else
    #_log "nothing to sweep for $1,$2"
    fi
}

gnome__setScreenKeyboardVisibile()
{
    gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled $1
}

Screen__getResolution()
{
    local -n __out_x=$1
    local -n __out_y=$2

    read __out_x __out_y < <(xrandr --current | grep -oP '\d+x\d+' | tr x ' ')
}

Desktop__getResolution()
{
    local -n __out_x=$1
    local -n __out_y=$2

    read  __out_x __out_y < <(wmctrl -d|awk -F' ' '{ if ($2=="*") print $4;}'|tr x ' ')
}
    # Note wmctrl -d returns the dimension of the whole desktop


CPU__model()
{
    local -n __out_cpuModel=$1
    local __cpumodel
    #read -r __cpumodel < <(lscpu -J| jq -r '.lscpu[]|select(.field=="Model name:")'.data)
    read -r __cpumodel < <(lscpu|awk -F':' '{ if ($1 == "Model name") print $2}')
    __out_cpuModel="${__cpumodel}"
}
