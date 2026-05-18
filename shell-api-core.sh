#!/bin/bash
###############################################################################
#
# Copyright (c) 2024 Michel Mehl. All rights reserved.
#
# -----------------------------------------------------------------------------
#
# A Shell API gathering a set of basic useful functions. This file
# also provides a framework for setting up easily and quickly high quality
# shell applications (BASH).
#
# -----------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
###############################################################################
trap _cleanup EXIT SIGHUP SIGINT SIGTERM SIGQUIT SIGABRT

__SHELL_API_CORE_DIR__=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

if [[ -v "__SHELL_API_CORE__" ]]; then
    return 0
else
    __SHELL_API_CORE__=0
fi

__CALLER_APP__="$1"
export __SUDO__=""
__SHELL_API_CORE_LOADED__=0
__SHELL_CURRENT_APPNAME__=""
__SHELL_CURRENT_APP_JOB_ID__=""
__SHELL_TEST_GEN_EXAMPLES__=1

declare -A SHELL_API_DEP_LOADED

# --------------------------------------------------------------------------------------
# Color Palette API
# --------------------------------------------------------------------------------------

Term__text_mode=""
# Term__text_color is set as the concanetation of Term__text_fgcolor and Term__text_bgcolor
Term__text_color="" 
Term__text_fgcolor=""
Term__text_bgcolor=""
Term__reset_color='\033[0m'
Term__colorFormatString='\033[%s1%s2m'
Term__colorList=$(tput colors 2>/dev/null || echo "0")

declare -A _pal

declare -A Term__colorName2colorCodeMap
Term__colorName2colorCodeMap["black"]=0
Term__colorName2colorCodeMap["red"]=1
Term__colorName2colorCodeMap["green"]=2
Term__colorName2colorCodeMap["yellow"]=3
Term__colorName2colorCodeMap["blue"]=4
Term__colorName2colorCodeMap["purple"]=5
Term__colorName2colorCodeMap["cyan"]=6
Term__colorName2colorCodeMap["white"]=7

Term__setTextMode()
{
    Term__text_mode="$1"
}

declare -A Term__textMode2TextModeCode
Term__textMode2TextModeCode["normal"]=0;
Term__textMode2TextModeCode["bold"]=1;
Term__textMode2TextModeCode["italic"]=3;
Term__textMode2TextModeCode["underline"]=4;
Term__textMode2TextModeCode["blinking"]=5;
Term__textMode2TextModeCode["blinkingfast"]=6;
Term__textMode2TextModeCode["reverse"]=7;
Term__textMode2TextModeCode["hide"]=8;
Term__textMode2TextModeCode["cross"]=9;

Term__resetColorData() {  
    Term__text_fgcolor=${_pal["normal"]}
    Term__text_bgcolor=""
}

Term__resetColor() {  
    Term__text_fgcolor=${_pal["normal"]}
    Term__text_bgcolor=""
    echo -n -e "${Term__reset_color}" 
}

Term__setColorOn()
{
    Term__setColor "$@"
    echo -n -e "${Term__text_color}"
}
Term__setBgColorOn()
{
    Term__setColor "$@" true
    echo -n -e "${Term__text_color}"
}

Term__setColor()
{
    if ! test -n "${Term__colorList}" || test ${Term__colorList} -lt 8 ; then
        Term__text_color=""
        return 0
    fi

    local cname="$1"
    local isBackground=false
    local tmcode
    local _ccode
    local realccode
    local _ccodeOffset=30
    local _textmode="${Term__text_mode}"

    if [ $# -eq 1 ];  then
        isBackground=false
    fi

    if [ $# -ge 2 ];  then
        isBackground=$2
    fi
    if [ $# -eq 3 ] && ! $isBackground;  then
        _textmode="$3"
    fi

    if $isBackground; then  
        _ccodeOffset=40 
        _textmode=""
        tmcode=""
        if [ -z "cname" ] ; then
            Term__text_bgcolor=""
            return 0
        fi
    else
        if [ -z "cname" ] ; then
            Term__text_color="${Term__reset_color}"
            return 0
        fi
        if [ -z "$_textmode" ] ; then
            _textmode="normal"
        fi

        tmcode="${Term__textMode2TextModeCode["${_textmode}"]}"
    fi
        
    if [ ! -z "$tmcode" ] ; then tmcode="${tmcode};" ; fi
    _ccode=${Term__colorName2colorCodeMap["$cname"]}
    local _text_color="${Term__colorFormatString}"
    _text_color="${_text_color//%s1/$tmcode}"
    realccode=$((${_ccodeOffset} + ${_ccode}))
    _text_color="${_text_color//%s2/$realccode}"
    if $isBackground ; then
        Term__text_bgcolor="${_text_color}"
    else
        Term__text_fgcolor="${_text_color}"
    fi
    Term__text_color="${Term__text_bgcolor}${Term__text_fgcolor}"
    #printf "%s" ${Term__text_color}
}

:<<'EOF'
Feed the mal _pal which maps readable colors to the terminal escaped char
Readable colors are of the form:
[bg_]<color name>[_<text_mode>] 
If the text mode is not specified , it refers to the default normal text color 
If 'bg_' is specified, then the color refers to the background color.
Otherwise, it is foreground color
EOF
Term__buildPalette()
{
    local allcolNames=(${!Term__colorName2colorCodeMap[@]})
    local alltextModes=(${!Term__textMode2TextModeCode[@]})
    local col
    Term__text_bgcolor=""
    for col in "${allcolNames[@]}" ; do
        local txtmode
        for txtmode in "${alltextModes[@]}" ; do
            Term__setColor "$col" false "$txtmode"
            _pal["${col}_${txtmode}"]="${Term__text_fgcolor}"
            if [ "$txtmode" = "normal" ] ; then
                _pal["${col}"]="${Term__text_fgcolor}"
            fi

            Term__setColor "$col" true
            _pal["bg_${col}_${txtmode}"]="${Term__text_bgcolor}"
            if [ "$txtmode" = "normal" ] ; then
                _pal["bg_${col}"]="${Term__text_bgcolor}"
            fi

        done
    done
    # Term__resetColor prints an unprintable char on terminal 
    # to actual reset the color => this impacts man pages and help
    # Actually, here only the internal data needs to be reset
    #Term__resetColor
    Term__resetColorData
}

Term__showPalette()
{
    local all=(${!_pal[@]})
    local col
    for col in "${all[@]}" ; do
        printf "$col: %s\n" "${_pal[$col]}"
    done    
}

Term__testColors()
{
    local allcolNames=(${!Term__colorName2colorCodeMap[@]})
    local  alltextModes=(${!Term__textMode2TextModeCode[@]})
    local col
    for col in "${allcolNames[@]}" ; do
        local txtmode
        for txtmode in "${alltextModes[@]}" ; do
            Term__setColor "$col" false "$txtmode"
            echo -e "${Term__text_color}$col $txtmode${Term__reset_color}"
            #printf "$col $txtmode:%s\n" "${Term__text_color}" >> log.txt # DEBUG

            Term__setColor "$col" true "$txtmode"
            Term__setColor "white" false "$txtmode"
            echo -e "${Term__text_color}$col $txtmode with BACKGROUND${Term__reset_color}"
            #printf "$col $txtmode:%s\n" "${Term__text_color}" >> log.txt # DEBUG
            Term__resetColor
        done
    done
    Term__resetColor
}

_colorprint() {
    echo -n -e "${Term__text_color}$1"
    Term__resetColor
}

:<<'EOF'
Colors the passed text with the specified color without 
impacting the current terminal setting (resets to normal)
EOF
_colorText() {
    echo -n -e "${_pal["$2"]}$1${Term__reset_color}"
}

#Term__testColors
Term__buildPalette
#Term__showPalette
#exit 0

# --------------------------------------------------------------------------------------
# Shell API framework API
# --------------------------------------------------------------------------------------

:<<'EOF'
Loads another script file by sourcing it (if not loaded yet before). 
Prior to sourcing, the global var __SHELL_SOURCE_NAME__ is set to
hold the basename of the sourced script. __SHELL_SOURCE_NAME__ is restored
to previous value after the sourcing.

@param [1] name of the script without extension
@param [2] parent dir path of the script, relatively to this.
@return 1 on error (invalid args), 0 otherwise. 
EOF

_load() {
    if [ $# -ge 1 ] ; then
        local scriptName="$1"
        local parentDir="$2"
        local fileCorename
        File__corename "${scriptName}" fileCorename
        local import_define="__${fileCorename}__"
        Str__toUpper import_define
        Str__replace import_define "-" "_"        
        # _log_dbg "CHECK: '$import_define'"
        if [[ ! -v "${import_define}" ]]; then
            _log_dbg "sourcing '${__SHELL_API_CORE_DIR__}/${parentDir}/${scriptName}.sh'"
            local cur_SRC_NAME="${__SHELL_SRC_NAME__}"
            __SHELL_SRC_NAME__="$fileCorename"
            #_log_dbg "_LOAD SHELL SRC NAME : '${__SHELL_SRC_NAME__}'"
            source "${__SHELL_API_CORE_DIR__}/${parentDir}/${scriptName}.sh"
            __SHELL_SRC_NAME__="${cur_SRC_NAME}" # restore value prior to sourcing
        fi
        return 0
    else
	    _log_err "${FUNCNAME[0]}: invalid use. 1 or 2 arg(s) expected, $# passed ($*)"
        echo -n ""
        return 1
    fi
}

loadm='read _load_mod 
    echo "!!!! -$_load_mod-"
'
_loadm='read _load_mod &&
    __shell_api_fileCorename="" && File__corename "${_load_mod}" __shell_api_fileCorename && 
    __shell_api_import_define="__${__shell_api_fileCorename}__" &&  Str__toUpper __shell_api_import_define &&  Str__replace __shell_api_import_define "-" "_" &&
    if [[ ! -v "${__shell_api_import_define}" ]]; then _log_dbg "sourcing ${__SHELL_API_CORE_DIR__}/${_load_mod}.sh";  __shell_api_cur_SRC_NAME="${__SHELL_SRC_NAME__}"; __SHELL_SRC_NAME__="${__shell_api_fileCorename}"; source "${__SHELL_API_CORE_DIR__}/${_load_mod}.sh";__SHELL_SRC_NAME__="${__shell_api_cur_SRC_NAME}" ;fi
'

_loada='read _load_app &&
    appName="${__SHELL_CURRENT_APPNAME__}" &&
    Str__toUpper appName &&
    appDirVar="\${${appName}__VARS[\"MY_DIR\"]}" &&
    eval source "${appDirVar}/${_load_app}" 
'


:<<'EOF'
Standard/generic end-user wrapper for dealing with package dependencies.
EOF

_loadDep() {
    local dep           # a dependency can be formatted like lsblk@util-linux
    local depApp
    local depPkg
    local allargs=("$@")
    local allActualArgs=()

    # Check first if not yet cached
    for dep in "${allargs[@]}"
    do
        Str__split "$1" depApp "@" depPkg 0

        if [ -z "${SHELL_API_DEP_LOADED["$depPkg"]}" ] ; then
            allActualArgs+=("$depPkg")
        #DEBUG
        #else
        #    _log_high "Dependency $depPkg already loaded according to cache"
        fi
    done

    if [ ${#allActualArgs[@]} -eq 0 ] ; then
        return 0
    fi

    _invokeCallback loadDep "${allActualArgs[@]}"

    if [ $? -eq 0 ] ; then
        for dep in "${allActualArgs[@]}"
        do
            #_log_dbg "_loadDep: raw dep string: $dep"        

            local alternativesString=""
            local expectedProgForAlternatives=""
            Str__split "$1" expectedProgForAlternatives "@" alternativesString 0
            readarray -t -d'|' alternatives <<< "$alternativesString"    

            local alternCnt=0
            while [ $alternCnt -lt ${#alternatives[@]} ] ; do
                local aPkg="${alternatives[$alternCnt]}"
                Str__trimEnd "$aPkg" aPkg

                #_log_dbg "_loadDep: dep string: $aPkg"        
                SHELL_API_DEP_LOADED["$aPkg"]=0
                alternCnt=$(($alternCnt + 1))
            done
        done
    fi
}

:<<'EOF'
Function to be called by any script API to check whether it has been already sourced or not.
When not loaded yet, it defines a global variable which existence means script file had been
sourced yet before.

Typical use:
  if _loaded "${BASH_SOURCE[0]}"  ; then
   return 0
  fi

@param [1] path to the source file of the calling script
@return 0 if already loaded, 1 otherwise.  
EOF

_loaded() {
    local filePath="$1"
    Str__toTail filePath "/"
    local import_define="__${filePath%.*}__" # take only the core filename without extension, avoiding using subshells
    Str__toUpper import_define
    Str__replace import_define "-" "_"

    #_log_dbg "CHECK: '$import_define'"
    if [[ ! -v "${import_define}" ]]; then
        #echo "defining ${import_define}"
        _log_dbg "defining ${import_define}"
        eval "${import_define}=0"
:<<'EOF'
        local ftype=`type -t ${import_define}init`
        if [ "$ftype" == 'function' ] ; then
            eval "${import_define}init"
            eval "declare -A Dev__fstype2PartUUID"
        fi
EOF
        return 1
    else
        return 0
    fi
}

:<<'EOF'
Standard/generic end-user wrapper for handling usage errors by doing the following:
- display of a script usage. The calling script-specific usage is displayed by 
  invoking a callback function formatted <appname>__usage where <appname> is 
  given by first parameter
- display any error specified by second parameter on standard error
- exit process with code - 1 
 
Optionally displays an error message if second argument is specified
 @param [1] optional error message to be displayed
EOF

_usage() {
    local msg="$1"
    if [ ! -z "$msg" ] ; then
        echo
        _log_err "$msg"
    fi
    _invokeCallback usage "$msg"
    exit -1
}

:<<'EOF'
Short usage function.
Standard/generic end-user wrapper for handling usage errors by doing the following:
- display of a script usage. The calling script-specific usage is displayed by 
  invoking a callback function formatted <appname>__susage where <appname> is 
  given by first parameter
- display any error specified by second parameter on standard error
- exit process with code - 1 
 
Optionally displays an error message if second argument is specified

@param [1] optional error message to be displayed
EOF

_susage() {
    local msg="$*"
    if [ ! -z "$msg" ] ; then
        echo "" 1>&2
        _log_err "$msg"
        echo "" 1>&2
    fi
    _invokeCallback susage "$msg"
    exit -1
}

:<<'EOF'
Invokes safely an application callback, displaying
a warning if the callback does not exist.
@param [1] callback function name
EOF

_invokeCallback() {
    local callback="$1"
    shift
    local argc=$#
    local appName="${__SHELL_CURRENT_APPNAME__}"
    if Env__fn_exists "${appName}__${callback}" ; then
        if [ $argc -eq 0 ] ; then
            ${appName}__${callback}
        else
            local argv=("$@")
            ${appName}__${callback} "${argv[@]}"
        fi
    else
        _log_warn "expected function '${appName}__${callback}' is not defined."
    fi
}

:<<'EOF'
Standard/generic end-user wrapper for handling help doc by doing the following:
- display of a script app help. The calling script-specific help is displayed by 
  invoking a callback function formatted <appname>__help 
  where <appname> is __SHELL_CURRENT_APPNAME__
  If any  argument is specified, the call back is <appname>__fullhelp 
- exit process with code 0 
 
Optionally displays an error message if second argument is specified

@param [1] any string 
EOF

_help() {    
    local callback=""
    if [ $# -ge 1 ] ; then
        callback=fullhelp
    else
        callback=help
    fi
    _invokeCallback "$callback"
    exit 0
}

:<<'EOF'
Displays script options according to the description list of all options 
as stored in global variable <APPNAME>__OPTION_LIST_DESC to be passed on as first argument
and <APPNAME>__OPTION_LIST_ARGS to be passed on as second argument
EOF

_options() {
    local -n OPTION_LIST_DESC=$1
    local -n OPTION_LIST_ARGS=$2
    local -n OPTION_LIST_INTERN=$3
cat << EOF
OPTIONS DETAILS:

EOF
    local k=0
    local found=1
    for k in ${!OPTION_LIST_DESC[@]}
    do
            local opt1=${k%%|*}
            local opt2=${k##*|}
            if [ ! -v OPTION_LIST_INTERN["$k"] ] ; then

                echo -n " ${k//|/,}"
                if [ "${OPTION_LIST_ARGS["$k"]}" == "0" ] ; then
                        echo -n " <arg>"
                fi
                echo
                local desc="${OPTION_LIST_DESC[$k]}"
                local line=""
                #echo "$desc"
                while IFS= read -r line
                do
                        echo "    $line"
                done <<<"$desc"

            fi
    done
}

:<<'EOF'
Displays a short synopsis of the options according to the description list of all options 
as stored in global variable <APPNAME>__OPTION_LIST_DESC.
EOF

_soptions() {
    local -n OPTION_LIST_DESC=$1
    local -n OPTION_LIST_SDESC=$2
    local -n OPTION_LIST_ARGS=$3
    local -n OPTION_LIST_ARGS_TYPE=$4
    local -n OPTION_LIST_INTERN=$5
    
cat << EOF
EOF

    local k=0
    local found=1
    declare -A displayOptionList
    local maxOptionListLength=0
    local maxAllowedOptionListLength=50
    for k in ${!OPTION_LIST_DESC[@]}
    do
            local opt1=${k%%|*}
            local opt2=${k##*|}
            if [ ! -v OPTION_LIST_INTERN["$k"] ] ; then
              #echo -n " ${k//|/, }"
              displayOptionList["$k"]=$(echo -n " ${k//|/, }")
              if [ "${OPTION_LIST_ARGS["$k"]}" == "0" ] ; then    # one mandatory argument
                if [ -v OPTION_LIST_ARGS_TYPE["$k"] ] ; then
                  #echo "=${OPTION_LIST_ARGS_TYPE["$k"]}"
                   displayOptionList["$k"]="${displayOptionList["$k"]} $(echo -n "=${OPTION_LIST_ARGS_TYPE["$k"]}")"
                else
                  #echo "=<arg>"
                   displayOptionList["$k"]="${displayOptionList["$k"]} $(echo -n "=<arg>")"           
                fi
              elif [ "${OPTION_LIST_ARGS["$k"]}" == "2" ] ; then  # one optional argument
                if [ -v OPTION_LIST_ARGS_TYPE["$k"] ] ; then
                  #echo "=[${OPTION_LIST_ARGS_TYPE["$k"]}]"
                   displayOptionList["$k"]="${displayOptionList["$k"]} $(echo -n "=[${OPTION_LIST_ARGS_TYPE["$k"]}]")"
                else
                   displayOptionList["$k"]="${displayOptionList["$k"]} $(echo -n "=<arg>")"
                fi
              #else
                  #echo
                   #displayOptionList["$k"]="${displayOptionList["$k"]} $(echo)"
              fi
            fi
            local len=${#displayOptionList["$k"]}
            if  [ $len -lt $maxAllowedOptionListLength ] && [ $len -gt $maxOptionListLength ]  ; then maxOptionListLength=$len; fi
    done
    #echo "MAX LEN=$maxOptionListLength"
    for k in ${!displayOptionList[@]}
    do
      local len=${#displayOptionList["$k"]}
      echo -n "${displayOptionList[$k]}"
      if  [ $len -lt $maxAllowedOptionListLength ]  ; then
        Str__spaces $(($maxOptionListLength - $len))
      fi
    if [ -v OPTION_LIST_SDESC["$k"] ] ; then
      echo " ${OPTION_LIST_SDESC["$k"]}"
    else
      echo " ${OPTION_LIST_DESC["$k"]}"
    fi
    #  echo " toto"
    done
}


:<<'EOF'
Standard/generic end-user wrapper for parsing argument. 
It handles the -h/--help argument
invoking a callback function formatted <appname>__help
where <appname> is __SHELL_CURRENT_APPNAME__,
ending calling _quit

It handles the --man argument
invoking a callback function formatted <appname>__man
where <appname> is __SHELL_CURRENT_APPNAME__
ending calling _quit
EOF

_parseArgs() {
    local argv=("$@")
    local argc=${#argv[@]}
    local new_argv=()
    local arg=""
    for arg in "${argv[@]}"        
    do
        case "$arg" in
        --man) 
            _invokeCallback man
            __quit
            ;;
        -h|--help) 
            _invokeCallback help
            __quit
            ;;
        -v|--version) 
            _invokeCallback version
            __quit
            ;;
        *) 
            new_argv+=("$arg") 
            ;;
        esac
    done
    #local new_argc=${#new_argv[@]}
    #if [ ${new_argc} -gt 0 ] ; then
        _invokeCallback parseArgs "${new_argv[@]}"
    #else
    #    return 0
    #fi
}

_parseFromArgToVars() {
    _log_dbg "_parseFromArgToVars '$@'"

    local -n OPTION_LIST_DESC=$1
    local -n OPTION_LIST_ARGS=$2
    local -n OPTION_LIST_ACTI=$3
    local -n OPTION_LIST_VALS=$4
    local -n out_argc=$5
    local -n out_arg_cnt=$6
    shift 6
    local __argv_o=("$@")
    local __argv=()
    local __argc=0
    local __arg_cnt=0
    local __arg=""
    local __prevarg=""

    _log_dbg "_parseFromArgToVars out_argc=${!out_argc} ${__argv_o[@]}"

    # First preprocess args to identify assigned option value --x=Y in order to split them into two
    for __arg in "${__argv_o[@]}"        
    do
            local optWithValueStart=${__arg%%--*}
            if [ -z "$optWithValueStart" ] ; then
                    local optName=${__arg%%=*}
                    local optVal=${__arg##*=}
                    __argv+=("$optName")       

                    if [ "$__arg" != "$optVal" ] ; then
                            __argv+=("$optVal")
                    else
                            local k=0
                            for k in ${!OPTION_LIST_DESC[@]}
                            do
                                    local opt1=${k%%|*}
                                    local opt2=${k##*|}
                                    if [ "$__arg" == "$opt1" ] || [ "$__arg" == "$opt2" ] ; then
                                            if [ "${OPTION_LIST_ARGS["$k"]}" == "0" ] ; then # value expected
                                                    local optName=${__arg%%=*}
                                                    #_log_dbg "'$__arg' '$optName'"
                                                    if [ "$__arg" == "$optName" ] ; then
                                                            _susage "A value is mandatory for option '$optName'"    
                                                    fi   
                                            fi
                                            break
                                    fi
                            done
                    fi
            else
                    __argv+=("$__arg")
            fi
    done
    __argc=${#__argv[@]}

    # process all arguments
    for __arg in "${__argv[@]}"        
    do
            _log_dbg "process all arguments ${__argc}: $__arg '$__prevarg' keys:'${!OPTION_LIST_DESC[@]}'"

            # try process with new map
            local k=0
            local found=1
            for k in ${!OPTION_LIST_DESC[@]}
            do
                #_log_dbg "test key $k: opt1=$opt1 opt2=$opt2 args?'${OPTION_LIST_ARGS["$k"]}' action?'${OPTION_LIST_ACTI["$k"]}'"
                    local opt1=${k%%|*}
                    local opt2=${k##*|}
                    if [ "$__arg" == "$opt1" ] || [ "$__arg" == "$opt2" ] ; then
                            _log_dbg "MATCH key $k: opt1=$opt1 opt2=$opt2 args?'${OPTION_LIST_ARGS["$k"]}' action?'${OPTION_LIST_ACTI["$k"]}'"
                            if [ ! -z "${OPTION_LIST_ACTI["$k"]}"  ] ; then
                                    eval "${OPTION_LIST_ACTI["$k"]}" 
                            fi

                            if [ "${OPTION_LIST_ARGS["$k"]}" == "1" ] ; then
                                    __prevarg=""
                            else
                                    __prevarg="$k" 
                            fi
                            found=0
                            break
                    fi
            done

            if [ $found -ne 0 ] ; then 
                    _parseArgsProcessDashLessArg ${!OPTION_LIST_VALS} "$__arg" __prevarg $__arg_cnt # handle it as file or device
                    __arg_cnt=$?
            fi
    done

    if [ ! -z "$__prevarg" ] ; then
            if [ "${OPTION_LIST_ARGS["$__prevarg"]}" != 2 ] ; then
                    _susage "argument expected for option ${__prevarg}" # ${__prevarg//|/}"
            fi       

    fi

    out_argc="$__argc"
    out_arg_cnt="${__arg_cnt}"
    #_log_dbg "_parseFromArgToVars RETURN WITH out_argc=$out_argc"
    return 0
}

:<<'EOF'
Parse arguments callback:
- Processes argument which are not options (not starting with a dash).
- Processes option values by evaluating SUMO__OPTION_LIST_VALS[<option>], in which case
the option is given by second argumet.

The arguments processed is tracked by a counter passed on by ref. 
The 1st argument is interpreted as device/file
The 2nd argument is interpreted as mount point

@param [1] List giving the actions to perform for options with values
@param [2] argument value (which can be an option value)
@param [3] previous argument (reference). It should be empty since 'arg'' is not supposed to be an option.
@param [4] arg counter name (reference)
@returns incremented counter 
EOF

_parseArgsProcessDashLessArg()
{
    _log_dbg "_parseArgsProcessDashLessArg '$1' '$2' '$3'"
    local -n __OPTION_LIST_VALS=$1
    local __myarg="$2"
    local -n __myprevarg=$3
    local __myarg_cnt=$4

    if Str__startsWith "$__myarg" "-" ; then
            _susage "unknown option '$__myarg'"
    fi
    if [ -z "$__myprevarg" ] ; then
            _invokeCallback parseArgsHandleOptionLessArg ${__myarg_cnt} "$__myarg" 

            if [ $? -ne 0 ] ; then
                _susage "unexpected argument '$__myarg'"
            fi
            return $(( __myarg_cnt + 1 ))
    else
            if [ ! -z "${__OPTION_LIST_VALS[$__myprevarg]}" ] ; then
                    eval "${__OPTION_LIST_VALS[$__myprevarg]}"
            else
                    _susage "unexpected argument '$__myarg' following '$__myprevarg'"
            fi
    fi
    __myprevarg=""        
    return $__myarg_cnt
}

:<<'EOF'
App shell quitting.

Ensures a fault-less quitting of the shell.
By default it deactivates the trap for EXIT SIGHUP SIGINT SIGTERM SIGQUIT SIGABRT
and calls _exit function.
User may override default behavior by defining
a callback function of the form "<appname>__quit"
EOF

_quit() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    if Env__fn_exists "${appName}__quit" ; then
            local argv=("$@")
            _invokeCallback quit "${argv[@]}"
    else
        Term__reset
        __quit "$1"
    fi
}

:<<'EOF'
Straight application quitting and bypassing any user-defined quit function.

It deactivates the trap for EXIT SIGHUP SIGINT SIGTERM SIGQUIT SIGABRT
and calls _exit function.
EOF

__quit() {
        trap - EXIT SIGHUP SIGINT SIGTERM SIGQUIT SIGABRT
        _exit 0 "$1"    
}

:<<'EOF'
Exits the shell bailing out with an error message

@param [1] exit code
@param [2] error message to be displayed
EOF

_exit() {
    _writeDependenciesCache

    if [ ! -z "$2" ] ; then
        echo
        if [ $1 -eq 0 ] ; then
            _log "$2"
        else
            _log_err "$2"
        fi
    fi
    exit $1
}

:<<'EOF'
Standard/generic end-user wrapper for invoking main script function
Invokes a callback function formatted <appname>__quit 
where <appname> is __SHELL_CURRENT_APPNAME__
EOF

_main() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local argv=("$@")

    # Initialize initial values for log variables till initLog is called
    __LOG_FILE__="/dev/null" 
    __LOG_ERR_FILE__="/dev/null" 
    __LOG_WARN_FILE__="/dev/null" 

    _readConfig
    _readDependenciesCache

    if ! _readRecentList ; then
        _log_dbg "Failed to read recent list file."
    fi
    _invokeCallback main "${argv[@]}"
}

:<<'EOF'
Standard/generic end-user wrapper for cleaning up upon signal arising

It invokes a callback function formatted <appname>_cleanup, passing on
the exit code. Eventually, it calls system exit with the  initial caught
exit code

@param [1] any string 
EOF

_cleanup() {    
    local exitCode=$?
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local callback=""
    callback=cleanup

    local appName="${__SHELL_CURRENT_APPNAME__}"

    if Env__fn_exists "${appName}__${callback}" ; then
        _invokeCallback "$callback" ${exitCode}
    fi
    exit ${exitCode}
}

:<<'EOF'
Initializes this shell API framework.
Following global variables are set:
__SHELL_CURRENT_APPNAME__: 
  it is the argument passed while sourcing this core shell api. It gives
  the logical name of the application script
__SHELL_SRC_NAME__:
  Source file name of the first application script which sources this core shell api.
EOF

_initShellApi() {
    if [ $(id -u) -eq 0 ]; then
        __SUDO__=""
    else
        __SUDO__="sudo "
    fi

    __LOG_ERR_FILE__="/dev/null"
    __LOG_FILE__="/dev/null"
    __LOG_WARN_FILE__="/dev/null"

    # Sumo can also be used from another script and not as main app
    # To invoke it from another script:
    # <appname>__main <args>
    if [[ ! -v __SHELL_CURRENT_APPNAME__ ]] || [[ -z ${__SHELL_CURRENT_APPNAME__} ]] ; then
            __SHELL_CURRENT_APPNAME__="${__CALLER_APP__}"
    fi
    __SHELL_SRC_NAME__="$(basename $0)"

    _log_dbg "_initShellApi called. __SHELL_CURRENT_APPNAME__:${__SHELL_CURRENT_APPNAME__}, __SHELL_SRC_NAME__:${__SHELL_SRC_NAME__}"
    return 0
}

_setJobId()
{
    __SHELL_CURRENT_APP_JOB_ID__="$1"
}

:<<EOF
Initializes only the variables related to the message, warning, errors log files, in particular
with regard to the log file names and the number of messages:
__LOG_FILE__
__LOG_WARN_FILE__
__LOG_ERR_FILE__
__NB_LOG__
__NB_WARNING_LOG__
__NB_ERR_LOG__
EOF

_initLogVars() {
    __SHELL_API_LOGS_INITIALIZED__=0
    # Initialize the warning and error logs
    local __regularLog
    _getLogPath __regularLog
    local __warnLog
    _getLogWarnPath __warnLog
    local __errLog
    _getLogErrPath __errLog
}

:<<EOF
Initializes the log file: message, warning, errors.
EOF

_initLogs() {
    __SHELL_API_LOGS_INITIALIZED__=0
    # Initialize the warning and error logs
    local __regularLog
    _getLogPath __regularLog "--- Start loggging ---"
    local __warnLog
    _getLogWarnPath __warnLog "--- Start warning logging ---"
    local __errLog
    _getLogErrPath __errLog "--- Start error loggging ---"
}

:<<EOF
Returns the path to the existing configuration directory for the currently registered application (__SHELL_CURRENT_APPNAME__),
which is defined as <user home dir>/.config/<app name>/.

@param [1] reference to the variable where to store the configuration folder path
@returns 0 when a valid configuration folder exists (and was possibly created by this function), otherwise:
         1 when failing to create config dir, 
         2 when invalid config dir 
EOF
_getConfigDir()
{
    local -n out_configDirPath=$1

    local appName="${__SHELL_CURRENT_APPNAME__}"
    local __configDirPath="$HOME/.config/${appName}"
    if [ ! -e "$__configDirPath" ] ; then
        _log "Creating configuration directory '$__configDirPath'"
        if ! mkdir -p "$__configDirPath" ; then
            _log_warn "Failed to create configuration directory '$__configDirPath'. Please check the access permission."
            _log_warn "Ignoring configuration."
            _log_warn ""
            return 1
        fi
    elif [ ! -d "$__configDirPath" ] ; then
        _log_warn "Path '$__configDirPath' exists, but is not a directory. Please fix."
        _log_warn "Ignoring configuration."
        _log_warn ""
        return 2
    fi
    out_configDirPath="$__configDirPath"
    [ -d "$__configDirPath" ] 
}

_getRecentListFilePath() 
{
    local -n __outRecentPath=$1
    local configDirPath=""

    if ! _getConfigDir configDirPath ; then
        return 2
    fi

    __outRecentPath="${configDirPath}/recentlist.yml"
}

:<<EOF
Reads the recent list for the application. The configuration file is expected to 
be  <user home dir>/.config/<app name>/recentlist.yml. 

The values of the configuration are stored in a map named :
<appname in uppercase>__RECENT. The keys are the genuine YAML keys .

Example applied for Sumo:
for config line " my parameter : my value",
there will be value defined as follows
<APPNAME>__VARS["my parameter"]="my value"

@returns 0 on success, 
         2 when invalid config dir 
EOF

_readRecentList() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local lowerAppName="$appName"
    local upperAppName="$appName"

    Str__toLower lowerAppName
    Str__toUpper upperAppName
    
    _getRecentListFilePath configPath

    declare -A __configProperties
    exec 9> /var/lock/${lowerAppName}_recent
    if ! flock -x -w 10 9; then
         return 1
    fi
     if ! File__readYAMLLikeFile "$configPath" __configProperties ; then
         _log_dbg "Failed to read '$configPath'. Ignoring configuration."
         flock -u 9
         exec 9>&-
         return 3
     fi
     flock -u 9
     exec 9>&-

    #_log_dbg "_readRecentList: $configPath, size ${#__configProperties[@]}"
    local propKey
    for propKey in "${!__configProperties[@]}"
    do
        local propVal="${__configProperties[$propKey]}"
        #echo "RECENT : $propKey : $propVal" >&2
        local varMapKey="$propKey"
        local globVar="${upperAppName}__RECENT[\"$varMapKey\"]"
        eval "$globVar=\"${propVal}\""

        #_log_dbg "_readRecentList CHECK $globVar = $(eval echo \${$globVar})"
    done

    _invokeCallback "readRecentListPostCallback"
}

__getRecentListFilePath()
{
    local configDirPath=""
    local -n __out_recentListFilePath=$1
    if ! _getConfigDir configDirPath ; then
        return 2
    fi
    __out_recentListFilePath="${configDirPath}/recentlist.yml"    
}

_saveRecentList() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local lowerAppName="$appName"
    local upperAppName="$appName"
    local configDirPath=""

    Str__toLower lowerAppName
    Str__toUpper upperAppName
    
    if ! _getConfigDir configDirPath ; then
        return 2
    fi
    local configPath="${configDirPath}/recentlist.yml"
    local propKey
    local recentMapVarName=${upperAppName}__RECENT
    local keysCmd="\${!${recentMapVarName}[@]}"
    local keys=($(eval echo "$keysCmd"))
    #_log_dbg "_saveRecentList: ALL KEYS ${keys[@]}"
   (
    flock -w 10 9 || return 1
    echo -n "" >  "$configPath"
    for propKey in "${keys[@]}"
    do
        local valueFromKeyCmd="\${${recentMapVarName}[\"$propKey\"]}"
        local value=$(eval echo "$valueFromKeyCmd")
        #_log_dbg "WRITING KEY ${propKey}"
    
        local indirectionRecentMapVarName="${recentMapVarName}_KEY_INDIRECTION"
        local valueFromIndirecionKeyCmd="\${${indirectionRecentMapVarName}[\"$propKey\"]}"
        local indirectionKey=$(eval echo "$valueFromIndirecionKeyCmd")
        if [ ! -z "$indirectionKey" ] ; then
            #_log_dbg "_saveRecentList KEY : REPLACING KEY '$propKey' with '$indirectionKey'" 
            propKey="$indirectionKey"
        fi

        echo "\"$propKey\" : $value" >> "$configPath"
    done
    sync "$configPath"
    ) 9>/var/lock/${lowerAppName}_recent
}


_lockedFileGetAbsPath() {
    local -n __out_filename="$2"
    local configDirPath=""
    if ! _getConfigDir configDirPath ; then
        return 2
    fi
    __out_filename="${configDirPath}/$1"
}

_lockedFileRead() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local lowerAppName="$appName"
    local upperAppName="$appName"
    local configDirPath=""

    Str__toLower lowerAppName
    Str__toUpper upperAppName
    
    if ! _getConfigDir configDirPath ; then
        return 2
    fi

    local filePath="${configDirPath}/$1"

    exec 9> /var/lock/${lowerAppName}_${filepath}
    if ! flock -x -w 10 9; then
         return 1
    fi

    if [ -f "$filePath" ] ; then
        cat "$filePath"
    else
         _log_warn "File doest not exist: '$configPath'."
         flock -u 9
         exec 9>&-
         return 3
    fi
    flock -u 9
    exec 9>&-
}

_lockedFileWrite() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local lowerAppName="$appName"
    local upperAppName="$appName"
    local configDirPath=""

    Str__toLower lowerAppName
    Str__toUpper upperAppName
    
    if ! _getConfigDir configDirPath ; then
        return 2
    fi
    local filePath="${configDirPath}/$1"
    shift
    local op="$1"
    shift
    local content="$@"

    #_log "_lockedFileWrite : $filePath '$op' -> '$content'"

   (
    flock -w 10 9 || return 1
    #echo -n "" >  "$filePath"
    if [ "$op" == "a" ] ; then
        echo "$content" >> "$filePath"
    else
        echo "$content" > "$filePath"
    fi
    sync "$filePath"
    ) 9>/var/lock/${lowerAppName}_${filepath}
}


:<<EOF
Returns the log folder path, ensuring parent dirs are created
@param [1] the reference of the variable where to store the path
EOF
_getLogDir() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local lowerAppName="$appName"
    Str__toLower lowerAppName

    local -n out_logDir=$1
    out_logDir="$HOME/.local/${lowerAppName}"
    mkdir -p "${out_logDir}" # &> /dev/null
}

:<<EOF
Returns the user's log file path, ensuring parent dirs are created
If any parameter is specified, the log file is truncated and the __LOG_NB__ is reset to 0
@param [1] the reference of the variable where to store the path
EOF
_getLogPath() {
    local logDir
    _getLogDir logDir
    local -n out_logPath=$1

    if [ -z "${__SHELL_CURRENT_APP_JOB_ID__}" ] ; then
        out_logPath="${logDir}/log.txt"
    else
        out_logPath="${logDir}/log_${__SHELL_CURRENT_APP_JOB_ID__}.txt"
    fi
    if [ $# -eq 2 ] ; then  
        if [ ! -e "${out_logPath}" ] ; then echo -n "" > "${out_logPath}" ; fi
        echo "$2" >> "${out_logPath}"
    fi
    __LOG_FILE__="${out_logPath}"
    __LOG_NB__=0
}

:<<EOF
Returns the user's warning log file path, ensuring parent dirs are created
If any parameter is specified, the log file is truncated and the __LOG_NB_WARN__ is reset to 0
@param [1] the reference of the variable where to store the path
EOF
_getLogWarnPath() {
    local logDir
    _getLogDir logDir
    local -n out_warnPath=$1

    if [ -z "${__SHELL_CURRENT_APP_JOB_ID__}" ] ; then
        out_warnPath="${logDir}/log.txt"
    else
        out_warnPath="${logDir}/log_${__SHELL_CURRENT_APP_JOB_ID__}.txt"
    fi

    #out_warnPath="${logDir}/log_warning.txt" # should be overridable in futur versions
    if [ $# -eq 2 ] ; then  
        if [ ! -e "${out_warnPath}" ] ; then echo -n "" > "${out_warnPath}" ; fi
        echo "$2" >> "${out_warnPath}"
    fi
    __LOG_WARN_FILE__="${out_warnPath}"
    __LOG_NB_WARN__=0
}

:<<EOF
Returns the user's error log file path, ensuring parent dirs are created.
If any parameter is specified, the log file is truncated and the __LOG_NB_ERR__ is reset to 0
@param [1] the reference of the variable where to store the path
EOF
_getLogErrPath() {
    local logDir
    _getLogDir logDir
    local -n out_errPath=$1

    if [ -z "${__SHELL_CURRENT_APP_JOB_ID__}" ] ; then
        out_errPath="${logDir}/log.txt"
    else
        out_errPath="${logDir}/log_${__SHELL_CURRENT_APP_JOB_ID__}.txt"
    fi

    #out_errPath="${logDir}/log_error.txt" # should be overridable in futur versions
    if [ $# -eq 2 ] ; then  
        if [ ! -e "${out_errPath}" ] ; then echo -n "" > "${out_errPath}" ; fi
        echo "$2" >> "${out_errPath}"
    fi
    __LOG_ERR_FILE__="${out_errPath}"
    __LOG_NB_ERR__=0
}

:<<EOF
Returns the user's local configuration file path. 
Note this file is not created by this function and may not exist.
EOF

_getConfigFilePath() {
    local -n out_cfgFilePath=$1
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local lowerAppName="$appName"
    local upperAppName="$appName"
    local configDirPath
    Str__toLower lowerAppName
    Str__toUpper upperAppName
    
    if ! _getConfigDir configDirPath ; then
        return 2
    fi

    out_cfgFilePath="$configDirPath/${lowerAppName}.yml"    
}

:<<EOF
Reads the configuration for the application. The configuration file is expected to 
be  <user home dir>/.config/<app name>/<appname in lowercase>.yml. 
When this file does not exist, the function <appname>__getDefaultConfigFile is called if the function exists, in order to get
the appname's own default config file path.

The values of the configuration are stored in a map named :
<appname in uppercase>__VARS. The keys are the YAML keys in upper case where spaces are replaced with "_"

Example applied for Sumo:
for config line " my parameter : my value",
there will be value defined as follows
<APPNAME>__VARS["MY_PARAMETER"]="my value"


@returns 0 on success, 
         2 when invalid config dir 
         3 when invalid config file or failed to read it
         4 Sumo-default config does not exist or User-specific config does not exist

EOF

_readConfig() {
    #__LOG_DEBUG__=0 # for dev

    local appName="${__SHELL_CURRENT_APPNAME__}"
    local lowerAppName="$appName"
    local upperAppName="$appName"
    local configDirPath
    Str__toLower lowerAppName
    Str__toUpper upperAppName

    if ! _getConfigDir configDirPath ; then
        return 2
    fi

    local configPath="$configDirPath/${lowerAppName}.yml"
    #_log_dbg "_readConfig configPath: $configPath in $configDirPath"

    # Config file is optional
    if [ ! -e "$configPath" ] ; then
        local callback="getDefaultConfigFile"
        if Env__fn_exists "${appName}__${callback}" ; then
            local defaultConfigPath
            _invokeCallback "${callback}" defaultConfigPath

            #_log_dbg "reading default configPath: $configPath"
            if [ ! -e "$defaultConfigPath" ] ; then
                _log_dbg "default config does not exist: $defaultConfigPath"
                return 4
            fi
            _log_high "Creating user's configuration file '$configPath' from '$defaultConfigPath'"
            cp "$defaultConfigPath" "$configPath"
            if [ $? -ne 0 ] ; then
                _log_warn "Failed to create user's configuration file '$configPath'. Taking default one '$defaultConfigPath'."
                configPath="$defaultConfigPath"
            fi
        else
            _log_dbg "User-specific config does not exist: $configPath"
            return 4
        fi
    fi

    declare -A __configProperties
    if ! File__readYAMLLikeFile "$configPath" __configProperties ; then
        _log_dbg "Failed to read '$configPath'. Ignoring configuration."
        return 3
    fi

    #_log_dbg "__configProperties:${!__configProperties[@]}  ${__configProperties[@]}"
    
    local propKey
    for propKey in "${!__configProperties[@]}"
    do
        local propVal="${__configProperties[$propKey]}"
        #_log_dbg "CONFIG $propKey : $propVal" 
        Str__replace propVal "\"" "\\\""
        local varMapKey="$propKey"
        Str__toUpper varMapKey
        Str__replace varMapKey " " "_"
        local globVar="${upperAppName}__VARS[\"$varMapKey\"]"
        #echo "$globVar=\"${propVal}\"" # DEBUG
        eval "$globVar=\"${propVal}\""

#            _log_dbg "CHECK $globVar = $(eval echo \${$globVar})"
    done

    return 0
}

_appendConfig() {
    local paramname="$1"
    local paramvalue="$2"
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local lowerAppName="$appName"
    local upperAppName="$appName"
    local configDirPath
    Str__toLower lowerAppName
    Str__toUpper upperAppName
    
    if ! _getConfigDir configDirPath ; then
        return 2
    fi

    local configPath="$configDirPath/${lowerAppName}.yml"
    #_log_dbg "configPath: $configPath in $configDirPath"
    if [ -e "$configPath" ] ; then
        Str__toLower paramname
        local tmpf=$(mktemp)
        grep -v ^"${paramname}:" "$configPath" > "$tmpf"
        echo "${paramname}: ${paramvalue}" >> "$tmpf"
        mv -f "$tmpf" "$configPath"
        [ $? -eq 0 ] || return 1
    fi
}

_getDependenciesCacheFile()
{
    local -n __outCacheFile=$1

    local localDirPath
    if ! _getLogDir localDirPath ; then # _getLogDir points to .local, should be renamed
        return 2
    fi

    __outCacheFile="$localDirPath/dependencies.yml"
}

_readDependenciesCache()
{
    #return 0 #  DEBUG USE THIS TO SWITCH OFF CACHE FOR TEST PURPOSES

    local cachePath
    if ! _getDependenciesCacheFile cachePath ; then
        return 1
    fi

    if [ -f "${cachePath}" ] ; then
        YAML__readAll "${cachePath}" SHELL_API_DEP_LOADED
        YAML__normalize SHELL_API_DEP_LOADED
        
        # DEBUG
        # _log "BEGIN Read dependencies"
        # YAML__dumpAll SHELL_API_DEP_LOADED
        # _log "END Read dependencies"
    else
        # Do not display that. Some tool like arcv rely on the standard output
        # at execution to get revision number. Rather, create the file
        # DEBUG ONLY
        #_log_warn "No package dependencies cache file ${cachePath} available."
        return 0
    fi
}

_writeDependenciesCache()
{
    local cachePath
    _getDependenciesCacheFile cachePath
    YAML__writeAll "${cachePath}" SHELL_API_DEP_LOADED

    #_log_high "_writeDependenciesCache CALLED" # DEBUG
}


# --------------------------------------------------------------------------------------
# Log API
# --------------------------------------------------------------------------------------

:<<'EOF'
Displays the passed argument string on the standard error output if __LOG_DEBUG__ var. exists.
The default behavior can be overriden by a user-defined function of the form
<appname>___log_dbg
where <appname> the argument passed while sourcing this core shell api. 
By default, the line is prefixed with [debug].
EOF

_log_dbg() {
    if [ -v __LOG_DEBUG__ ] ; then
    
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local callback="${FUNCNAME[0]}"
    local argv=("$@")
    if Env__fn_exists "${appName}__${callback}" ; then
        _invokeCallback "${callback}" "${argv[@]}"
    elif [ -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
        Term__setColor "purple" true 
        _colorprint "debug"| tee -a "${__LOG_ERR_FILE__}" >&2

cat <<EOF | tee -a "${__LOG_FILE__}" >&2
 $@
EOF
    else
        Term__setColor "purple" true 
        _colorprint "debug" >&2
cat <<EOF >&2
 $@
EOF
        Term__resetColor
    fi

    fi # see above 'fi' for if [ -v __LOG_DEBUG__ ] ; then
}


:<<'EOF'
Displays the passed argument string on the standard error output
and inserts it in the error log file.
The default behavior can be overriden by a user-defined function of the form
<appname>___log_err
where <appname> the argument passed while sourcing this core shell api. 
By default, the line is prefixed with [error].
EOF

_log_err() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local callback="${FUNCNAME[0]}"
    local argv=("$@")
    __LOG_NB_ERR__=$((${__LOG_NB_ERR__}+1))
    if Env__fn_exists "${appName}__${callback}" ; then
        _invokeCallback "${callback}" "${argv[@]}"
    elif [ -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
        Term__setColor "red" true 
        _colorprint "error"| tee -a "${__LOG_ERR_FILE__}" >&2
cat <<EOF | tee -a "${__LOG_ERR_FILE__}" >&2
 $@
EOF
    else
        Term__setColor "red" true 
        _colorprint "error" >&2
cat <<EOF >&2
 $@
EOF
        Term__resetColor
    fi

}

:<<'EOF'
Displays the passed argument string as a warning on the standard error output
and inserts it in the warning log file.
The default behavior can be overriden by a user-defined function of the form
<appname>___log_warb
where <appname> the argument passed while sourcing this core shell api. 
By default, the line is prefixed with [warning].
EOF

_log_warn() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local callback="${FUNCNAME[0]}"
    local argv=("$@")

    __LOG_NB_WARN__=$((${__LOG_NB_WARN__}+1))
    if Env__fn_exists "${appName}__${callback}" ; then
        _invokeCallback "${callback}" "${argv[@]}"
    elif [ -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
        Term__setColor "yellow" true 
        _colorprint "warning"| tee -a "${__LOG_ERR_FILE__}" >&2

cat <<EOF | tee -a "${__LOG_WARN_FILE__}" >&2
 $@
EOF
    else
        Term__setColor "yellow" true 
        _colorprint "warning" >&2
cat <<EOF >&2
 $@
EOF
        Term__resetColor
    fi
}


:<<'EOF'
Same as _log(), except it is reserved for messages of higher importance by displaying
'info' with blue background to catch attention

EOF
_log_high() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local callback="${FUNCNAME[0]}"
    local argv=("$@")

    __LOG_NB__=$((${__LOG_NB__}+1))

    if Env__fn_exists "${appName}__${callback}" ; then
        _invokeCallback "${callback}" "${argv[@]}"
    elif [ -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
        Term__setColor "blue" true 
        _colorprint "info"| tee -a "${__LOG_FILE__}"

cat <<EOF | tee -a "${__LOG_FILE__}"
 $@
EOF
    else
        Term__setColor "blue" true     
        _colorprint "info" 
cat <<EOF
 $@
EOF
        Term__resetColor
    fi
}


:<<'EOF'
Displays the passed arguments on the standard output and writes it in the log
file if log files were initialized (see initLogs).
The default behavior can be overriden by a user-defined function of the form
<appname>___log
where <appname> the argument passed while sourcing this core shell api. 
EOF

_log() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local callback="${FUNCNAME[0]}"
    local argv=("$@")

    __LOG_NB__=$((${__LOG_NB__}+1))

    if Env__fn_exists "${appName}__${callback}" ; then
        _invokeCallback "${callback}" "${argv[@]}"
    elif [ -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
cat <<EOF | tee -a "${__LOG_FILE__}"
$@
EOF
    else
cat <<EOF
$@
EOF
    fi
}

:<<'EOF'
Same as _log(), but only writes the log file and no message is displayed on terminal.
EOF
_logf() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local callback="${FUNCNAME[0]}"
    local argv=("$@")

    __LOG_NB__=$((${__LOG_NB__}+1))

    if Env__fn_exists "${appName}__${callback}" ; then
        _invokeCallback "${callback}" "${argv[@]}"
    elif [ -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
cat <<EOF >> "${__LOG_FILE__}"
$@
EOF
    fi
}


:<<'EOF'
Displays the passed shell array string on the standard output in the following format:
<array key>:<array value for that key>
The _log function is used for the display.
@param [1] name of the array. The array shall be passed by reference, not with all of its values.
EOF

_log_array() {
    local -n arr=$1
    local i=""

    _log "Array $1, ${#arr[@]} items:"
    for i in "${!arr[@]}"    
    do
        _log "  $i: ${arr[$i]}"
    done
}

:<<'EOF'
Same as _log, except there is no new line displayed.
EOF

_log_n() {
    #if [ ! -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
    #    return 1
    #fi

    local appName="${__SHELL_CURRENT_APPNAME__}"
    local callback="${FUNCNAME[0]}"
    local argv=("$@")
    if Env__fn_exists "${appName}__${callback}" ; then
        _invokeCallback "${callback}" "${argv[@]}"
    elif [ -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
        echo -e -n "$@" | tee -a "${__LOG_FILE__}"
    else
        echo -e -n "$@"
    fi
}


__SHELL_API_WORK_STATUS_TXT=""
__SHELL_API_WORK_STATUS_HT=""
_log_status() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local callback="${FUNCNAME[0]}"
    local argv=("$@")
    local headerType="$1"
    shift
    __SHELL_API_WORK_STATUS_TXT="$@"
    __SHELL_API_WORK_STATUS_HT="${headerType}"
    case "$headerType" in
        high) 
            Term__setColor "blue" true   
            if [ -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
                _colorprint "info "| tee -a "${__LOG_FILE__}"
            else
                _colorprint "info "
            fi
            ;;
        *) ;;
    esac
    if Env__fn_exists "${appName}__${callback}" ; then
        _invokeCallback "${callback}" "${argv[@]}"
    elif [ -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
        echo -e -n "$@" | tee -a "${__LOG_FILE__}"
    else
        echo -e -n "$@"
    fi
}
_log_status_end() {
    local res="$1"
    local resString=""
    case "$res" in
        ok|success) resString="[${_pal["black_bold"]}${_pal["bg_green"]} OK ${Term__reset_color}]";;
        nope|nok|fail) resString="[${_pal["white_bold"]}${_pal["bg_red"]} FAIL ${Term__reset_color}]";;
        *) ;;
    esac
    Term__eraseCurrentLine
     #echo -e -n "${__SHELL_API_WORK_STATUS_TXT}"
    _log_status "${__SHELL_API_WORK_STATUS_HT}" "${__SHELL_API_WORK_STATUS_TXT}"
    _log_n "$resString"
    _log ""
}

_log_vars_exit()
{
    _log_vars "$@"
    exit 0
}

_log_vars()
{
    local varlist=($@)
    local i=0
    for varname in "${varlist[@]}"  ;
    do
        local -n value=$varname
        if [ $i -gt 0 ] ; then
            _log_n ", "
        fi
        _log_n "$varname: '${value}'"
        i=$(($i+1))
    done
    _log ""
}

:<<'EOF'
Same as _log, except that the message is preceeded and followed by an empty line.
The default behavior can be overriden by a user-defined function of the form
<appname>___log_title
where <appname> the argument passed while sourcing this core shell api. 
EOF

_log_title() {
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local callback="${FUNCNAME[0]}"
    local argv=("$@")
    if Env__fn_exists "${appName}__${callback}" ; then
        _invokeCallback "${callback}" "${argv[@]}"
    elif [ -v __SHELL_API_LOGS_INITIALIZED__ ] ; then
cat <<EOF | tee -a "${__LOG_FILE__}"

$@

EOF
    else
cat <<EOF

$@

EOF
    fi
}

:<<'EOF'
Creates each component of the specified dir path (mkdir -p) if the 
dir path does not exit. Redirects errors in the error log files.
EOF

makeDir()
{
    if ! Args__checkMinCount "${FUNCNAME[0]}" 1 "$#" "usage: <dir path>"; then _exit -1 ; fi
    local dir="$1"
    [ -d "$dir" ] || mkdir -p "$dir" 2>>"${__LOG_ERR_FILE__}" 
}


:<<'EOF'
Exits if the passed folder does not exist 
EOF

trapDirExits()
{
    if ! Args__checkMinCount "${FUNCNAME[0]}" 1 "$#" "usage: <dir path> [<error code>]"; then _exit -1 ; fi
    local dir="$1"
    local errcode=-1
    if [ $# -gt 1 ] ; then errcode=$2 ; fi
    [ -d "$dir" ] || _exit $errcode "Required folder '$dir' does not exist."
}

:<<'EOF'
Exits if the passed file does not exist 
EOF

trapFileExits()
{
    if ! Args__checkMinCount "${FUNCNAME[0]}" 1 "$#" "usage: <file path> [<error code>]"; then _exit -1 ; fi
    local __in_file="$1"
    local errcode=-1
    if [ $# -gt 1 ] ; then errcode=$2 ; fi
    [ -f "${__in_file}" ] || _exit $errcode "Required file '${__in_file}' does not exist."
}


# --------------------------------------------------------------------------------------
# Shell enviroment API
# --------------------------------------------------------------------------------------
Env__LSB_RELEASE=""

:<<'EOF'
Tells whether the function exists and is defined.
EOF

Env__fn_exists() {
  # appended double quote is an ugly trick to make sure we do get a string -- if $1 is not a known command, type does not output anything
  [ `type -t $1`"" == 'function' ]
}

:<<'EOF'
Returns the name and version of the system distribution.
Name and version are separated separated by ' '
EOF

Env__distro() {
    if which lsb_release &>/dev/null ; then
        local var=$(lsb_release -a|awk -F ' ' '/^Description:/{printf ("%s-%s",$2,$3)}') 2>/dev/null
        echo "$var"
    else
        echo "unknown"
    fi
}

:<<'EOF'
Returns the name only of the system distribution
EOF

Env__distroname() {
    if which lsb_release &>/dev/null ; then
        local var="$(lsb_release -is)" 2>/dev/null
        echo "$var"
    else
        echo "unknown"
    fi
}

:<<'EOF'
Returns the version only of the system distribution
@param [1] the maximum number of version numbers requested. If not specified, original
extracted version is returned.
EOF

Env__distrover() 
{
    local nbNumbers=$1
    local -n __out_distover=$2
    if [ -z "${Env__LSB_RELEASE}" ] ; then
        if which lsb_release &>/dev/null ; then
           Env__LSB_RELEASE="$(lsb_release -sr)" 2>/dev/null
        else
            __out_distover="unknwon"
            return -1
        fi
    fi
    # Env__LSB_RELEASE="20.3.4" # FOR TEST

    local vernumbers=()
    readarray -t -d'.' vernumbers <<< "${Env__LSB_RELEASE}"
    __out_distover="${vernumbers[@]:0:$nbNumbers}"
    __out_distover="${__out_distover// /.}"
    Str__trimEnd "${__out_distover}" __out_distover
}

:<<'EOF'
Returns the name of the machine architecture.
By default, replaces x86_64 by amd64
EOF

Env__arch() {
    local arch="$(uname -m)"
    if [ "$arch" == "x86_64" ] ; then
        arch="amd64"
    fi
    echo "$arch"
}

# --------------------------------------------------------------------------------------
# String API
# --------------------------------------------------------------------------------------

#https://unix.stackexchange.com/questions/230673/how-to-generate-a-random-string
#
# generate random key : 
#   LC_ALL=C  tr -dc A-Za-z0-9 </dev/urandom | head -c 13
#   openssl rand -base64 12| tr -dc A-Za-z0-9
#   openssl rand -hex 12
#   xxd -l16 -ps /dev/urandom # HEXA
#   base64 < /dev/urandom | tr -d 'O0Il1+/' | head -c 44;
#
# Generate 7 passwords of length 13:
#    pwgen 13 7

Str__randomWord()
{
    local nbChars="$1"
    xxd -l${nbChars} -ps /dev/urandom
}

Str__diff()
{
    local tmp1=$(mktemp)
    local tmp2=$(mktemp)
    echo "$1" > "$tmp1"
    echo "$2" > "$tmp2"
    diff "$tmp1" "$tmp2"
    rm "$tmp1" "$tmp2" &>/dev/null
}

:<<'EOF'
Tests a string for emptiness
@param [1] input string to test for emptiness
EOF

Str__isEmpty() {
    [ ${#1} -eq 0 ]
}

:<<'EOF'
Returns a series of spaces which length is given by first parameter.
@param number of spaces
EOF

Str__spaces()
{
        #printf "${Str__BLANKLINE:0:$1}"
        printf "%${1}s"
}

:<<'EOF'
Indents a paragraph by inserting spaces at the start of each line.
@param[1] number of spaces to add
@param[2] ref to the var used as input and modified with the indended content.
EOF
Str__indent()
{
    local extraIndent="$(Str__spaces $1)"
    local -n __out_str=$2
    #local -n __in_out_for_indent=$2
    Str__prefix "$extraIndent" ${!__out_str}
}

Str__prefix()
{
    local __prefix="$1"
    local -n __in_out_for_indent=$2
    local indented=""
    out_res=""
    while IFS= read -r l 
    do
            if [ -z "${indented}" ] ; then
                    indented="${__prefix}${l}"
            else
                    indented="${indented}
${__prefix}$l"
            fi
    done <<<"${__in_out_for_indent}"
    __in_out_for_indent="${indented}"
    return 0
}

:<<'EOF'
Returns a sequence of the same size of length given by first parameter
@param [1] the char to repeat
@param [2] number of chars
EOF

Str__seq()
{
    #echo "seq '$1' '$2'" 1>&2 # dbg
    if [ "$1" == "-" ] ; then 
        # with "-" printf in else returns an error
        local cmd="for i in {1..$2}; do echo -n "$1"; done"
        c="\-"; 
    else
        local cmd="printf '$1%.0s' {1..$2}"
    fi
    eval "$cmd"
}

:<<'EOF'
Upcase the first letter of the passed argument string 
@param [1] input string
@return The input string with first letter downcased.
EOF

Str__len() {
    if [ $# -ne 1 ] ; then
    	_log_err "${FUNCNAME[0]}: invalid use. 1 arg expected, $# passed ($*)"        
        return 1        
    fi
    printf ${#1}
}

:<<'EOF'
Upcase the first letter of the passed argument string 
@param [1] in/out string
@return 0 on success, 1 if wrong arguments
EOF

Str__upcaseFirst() {
    if [ $# -eq 0 ] ; then
	    printf ""
    elif [ $# -eq 1 ] ; then
	    #printf "$1"|sed "s/^\([[:lower:]]\)/\U\1/g"
        local -n __in_string=$1
        local first=${__in_string:0:1}
        local rest=${__in_string:1}
        __in_string="${first^^}${rest}"

    else
	    _log_err "${FUNCNAME[0]}: invalid use. 1 arg expected, $# passed ($*)"
        return 1        
    fi
    return 0
}

:<<'EOF'
Returns the argument string in lowercase
@param [1] input string
@return lowercase string
EOF

Str__lower() {
    if [ $# -eq 1 ] ; then
        local __in_string="$1"
        Str__toLower __in_string # not efficient: echo -n "$1"|tr '[:upper:]' '[:lower:]'
        echo "${__in_string}"
    else
	    _log_err "${FUNCNAME[0]}: invalid use. 1 arg expected, $# passed ($*)"
        echo -n ""
        return 1
    fi
    return 0
}

:<<'EOF'
Lowercase the passed string by reference.
This version should be used instead of lower() when possible
since its definition prevents it to be called from a subshell
@param [1] input string, which is lowercased
EOF

Str__toLower() {
    local -n inout_res=$1
    inout_res="${inout_res,,}"
    return 0
}

:<<'EOF'
Returns the argument string in uppercase
@param [1] input string
@return lowercase string
EOF

Str__upper() {
    if [ $# -eq 1 ] ; then
        local __in_string="$1"
        Str__toUpper __in_string # not efficient: echo -n "$1"|tr '[:lower:]' '[:upper:]'	
        echo "${__in_string}"
    else
	    _log_err "${FUNCNAME[0]}: invalid use. 1 arg expected, $# passed ($*)"
        echo -n ""
        return 1
    fi
    return 0
}

:<<'EOF'
Uppercase the passed string by reference.
This version should be used instead of upper() when possible
since its definition prevents it to be called from a subshell
@param [1] input string, which is uppercased
EOF

Str__toUpper() {
    local -n inout_res=$1
    inout_res="${inout_res^^}"
    return 0
}

:<<'EOF'
Tells whether the passed string starts with another.
@param [1] input string
@param [2] expected start substring
@return 0: yes, 1:no
EOF

Str__startsWith() {
    if [ $# -eq 2 ] ; then
        local string="$1"
        local startString="$2"
        if [[ "$string" =~ ^${startString}.* ]] ; then
            return 0
        else
            return 1
        fi
    else
	    _log_err "${FUNCNAME[0]}: invalid use. 2 args expected, $# passed ($*)" 
        echo -n ""
        return 1
    fi        
}

Str__endsWith() {
    if [ $# -eq 2 ] ; then
        local string="$1"
        local endString="$2"
        if [[ "$string" =~ .*${endString}$ ]] ; then
            return 0
        else
            return 1
        fi
    else
	    _log_err "${FUNCNAME[0]}: invalid use. 2 args expected, $# passed ($*)" 
        echo -n ""
        return 1
    fi        
}


:<<'EOF'
Tells whether the passed string contains a substring.
@param [1] input string
@param [2] substring to search for
@return 0: yes, 1:no
EOF

Str__contains() {
    if [ $# -eq 2 ] ; then
        local string="$1"
        local searchStr="$2"
        if [[ "$string" =~ "${searchStr}" ]] ; then
            return 0
        else
            return 1
        fi
    else
	    _log_err "${FUNCNAME[0]}: invalid use. 2 args expected, $# passed ($*)"
        echo -n ""
        return 1
    fi        
}

:<<'EOF'
Return the string tail in commmon between both given input string,
regardless of char case and heading or trailing whitespaces.
@param [1] input string 1
@param [2] input string 2
@param [3] tail in commmon between both given input string, in lower case
EOF

Str__nbCommonEndString() {
    local s1="$1"
    local s2="$2"
    Str__trim "$s1" s1
    Str__trim "$s2" s2
    Str__toLower s1
    Str__toLower s2
    local -n res=$3
    local lasts1="${s1:0-1}"
    local lasts2="${s2:0-1}"
    res=""
    while [ "$lasts1" = "$lasts2" ] && [ ! -z "$s1" ] && [ ! -z "$s2" ]; do
        res="${lasts1}${res}"
        s1="${s1:0:-1}"
        s2="${s2:0:-1}"
        lasts1="${s1:0-1}"
        lasts2="${s2:0-1}"
    done
    if [ "$lasts1" = "$lasts2" ] ; then
        res="${lasts1}${res}"
    fi
}

:<<'EOF'
Squeezes multiple consecutive whitespaces to a single one
@param [1] input string to squeeze
@param [2] out result string
@param [3] Optional, char to squeeze, by default whitespaces ([[:space:]])
@returns the number of removed chars
EOF

Str__squeeze() {
    local in="$1"
    local -n res_out=$2

    local size=${#in}
    local squeezed=""
    local i=0
    local c=0
    local prevcIsSpace=1
    local removed=0
    local sqc="[[:space:]]"
    
    if [ $# -eq 3 ] ; then
        sqc="$3"
    else
        if ! Args__checkCount "${FUNCNAME[0]}" 2 "$#" ; then return -1 ; fi
    fi

    while [ $i -lt ${#in} ] ;
    do
        c="${in:$i:1}"
        if [[ "$c" == $sqc ]] ; then
            if [ $prevcIsSpace -ne 0 ] ; then
                squeezed="${squeezed}${c}"
                prevcIsSpace=0
            else
                removed=$(($removed + 1))
            fi
        else
            squeezed="${squeezed}${c}"
            prevcIsSpace=1
        fi

        i=$(( $i + 1 ))
    done

    res_out="$squeezed"
    return 0
}


:<<'EOF'
Replaces all the occurrences of the first string parameters
trimming leading and trailing occurrences and replacing
the rest with the value of the third parameter.
@param [1] input string to be processed
@param [2] string to escape
@param [3] replacement string 
@param [4] output resulting string 
@return 0
EOF

Str__escape() {
    local -n out_escape=$4
    Str__trim "$1" out_escape "$2"
    out_escape="${out_escape//$2/$3}"
    return 0
}

:<<'EOF'
Escapes all the occurrences of the pass char
inserting a backslash
@param [1] in/out input string to be escaped
@param [2] string to escape
@return 0
EOF

Str__escapeChar() {
    local -n __inout_s=$1
    local -n __in_char=$2
    __inout_s="${__inout_s//$2/\\$2}"
}

:<<'EOF'
Trims the passed string of the specified char on both of its ends
@param [1] string to be trimmed
@param [2] output variable
@param [3] char to be removed, is [[:space:]] by default
@param [4] The number of char to remove, by default all.
@return number of trimmed char in all
EOF

Str__trim() {
    local in="$1"
    local -n res_out=$2
    local c="[[:space:]]"
    if [ $# -ge 3 ] ; then
        c=$3
    fi
    local init=""
    while [ "$init" != "$in" ] ; do
        init="$in"
        in="${in#$c}"
        in="${in%$c}"
    done
    res_out="$in"
}


Str__trimOld() {
    local in="$1"
    local -n res_out=$2
    local c="[[:space:]]"
    if [ $# -ge 3 ] ; then
        c=$3
    fi
    local count=0 # means infinite
    if [ $# -eq 4 ] ; then
        count=$4
    fi
    if [ $# -gt 4 ] ; then
    	_log_warn "${FUNCNAME[0]}: at most 4 args expected, $# passed ($*)"
    fi
    local count_removed=0 # means infinite

    local curSize=${#in}
    local newSize=0
    while [ ${curSize} -ne ${newSize} ] && ([ $count -eq 0 ] || $count_removed -lt $count ])
    do
        curSize=${#in}
        in="${in#$c}"
        in="${in%$c}"
        newSize=${#in}
        count_removed=$(( $count_removed + $curSize - $newSize ))
    done
    res_out="$in"
    return ${count_removed}
}

:<<'EOF'
Same as Str__trim but attempts to remove only 1 occurrence with a very simple
implementation. Written for the sake of performance, since the regular variant
reveals to be much slower.
@param [1] string to be trimmed
@param [2] output variable
@param [3] char to be removed, is [[:space:]] by default
@param [4] The number of char to remove, by default all.
@return number of trimmed char in all
EOF
Str__trimOnce() {
    local in="$1"
    local -n res_out=$2
    local c="[[:space:]]"
    if [ $# -ge 3 ] ; then
        c=$3
    fi
    in="${in#$c}"
    in="${in%$c}"
    res_out="$in"
}

:<<'EOF'
Trims the passed string of the specified starting char
@param [1] string to be trimmed
@param [2] output variable
@param [3] char to be removed at the start of the string. Optional, is [[:space:]] by default
 @param [4] The number of char to remove, by default all.
@return number of trimmed char in all
EOF

Str__trimStart() {
    local in="$1"
    local -n res_out=$2
    local c="[[:space:]]"
    if [ $# -ge 3 ] ; then
        c=$3
    fi
    local init=""
    while [ "$init" != "$in" ] ; do
        init="$in"
        in="${in#$c}"
    done
    res_out="$in"
}


Str__skip() {
    local __in_ws="$1"
    local __in_s="$2"
    local -n __out_nbSkipped=$3
    local -n __out_s=$4
    __out_s="${__in_s#$__in_ws}"
    __out_nbSkipped=0
    while [ "${__in_s}" != "${__out_s}" ] ; do
        __out_nbSkipped=$((${__out_nbSkipped} + 1))
        __in_s="${__out_s}"
        __out_s="${__in_s#$__in_ws}"
    done
}

Str__skipWs() {
    local __in_s="${1}_"
    local -n __out_s=$2
    local -n __out_nbSkipped=$3
    read -r __out_s <<< "${__in_s}"
    __out_nbSkipped=$(( ${#__in_s} - ${#__out_s}))
    __out_s=${__out_s:0:-1}
}




Str__trimStart_old() {
    local in="$1"
    local -n res_out=$2
    local c="[[:space:]]"
    if [ $# -ge 3 ] ; then
        c=$3
    fi
    local count=0 # means infinite
    if [ $# -eq 4 ] ; then
        count=$4
    fi
    if [ $# -gt 4 ] ; then
    	_log_warn "${FUNCNAME[0]}: at most 4 args expected, $# passed ($*)"
    fi
    local count_removed=0 # means infinite

    local curSize=${#in}
    local newSize=0
    while [ ${curSize} -ne ${newSize} ] && ([ $count -eq 0 ] || $count_removed -lt $count ])
    do
        curSize=${#in}
        in="${in#$c}"
        newSize=${#in}
        count_removed=$(( $count_removed + $curSize - $newSize ))
    done
    res_out="$in"
    return ${count_removed}
}

:<<'EOF'
Trims the passed string of the specified ending char
@param [1] string to be trimmed
@param [2] output variable
@param [3] char to be removed at the end of the string. Optional, is [[:space:]] by default
@param [4] The number of char to remove, by default all.
@return number of trimmed char in all
EOF

Str__trimEnd() {
    local in="$1"
    local -n res_out=$2
    local c="[[:space:]]"
    if [ $# -ge 3 ] ; then
        c=$3
    fi
    local init=""
    while [ "$init" != "$in" ] ; do
        init="$in"
        in="${in%$c}"
    done
    res_out="$in"
}

Str__trimEnd_old() {
    local in="$1"
    local -n res_out=$2
    local c="[[:space:]]"
    if [ $# -ge 3 ] ; then
        c=$3
    fi
    local count=0 # means infinite
    if [ $# -eq 4 ] ; then
        count=$4
    fi
    if [ $# -gt 4 ] ; then
    	_log_warn "${FUNCNAME[0]}: at most 4 args expected, $# passed ($*)"
    fi
    local count_removed=0 # means infinite
    local curSize=${#in}
    local newSize=0
    while [ ${curSize} -ne ${newSize} ] && ([ $count -eq 0 ] || $count_removed -lt $count ])
    do
        curSize=${#in}
        in="${in%$c}"
        newSize=${#in}
        count_removed=$(( $count_removed + $curSize - $newSize ))
    done
    res_out="$in"
    return ${count_removed}    
}

:<<'EOF'
Gets  the last char of the passed string
and stores it in the second arg passed by reference
@param [1] input string
@param [2] last char
@return: char
EOF

Str__last() {
    local in="$1"
    local -n c=$2
    c="${in:0-1}"
    return 0
}

:<<'EOF'
Returns the first chars till to match
the first occurrence of the passed separator,
or the last occurrence if any third argument is specified.
@param [1] input string 
@param [2] separator
@param [3] recurse flag
@return the heading substring
@example $(head "www.example.com" .) -> "www"
@example $(head "www.example.com" . last) -> "www.example"
EOF

Str__head() {
    if [ $# -ge 3 ] ; then
        echo "${1%$2*}" # with only one %, go until last occurrence
    else
        echo "${1%%$2*}"
    fi
    return 0
}


Str__toHead() {
    local -n __toHeadInRef=$1
    if [ $# -ge 3 ] ; then
        __toHeadInRef="${__toHeadInRef%$2*}" # with only one #, go until last occurrence
    else
        __toHeadInRef="${__toHeadInRef%%$2*}" 
    fi
    return 0
}
:<<'EOF'
Returns the last chars till to match
the first occurrence of the passed separator,
or the last occurrence if any third argument is specified,
when scanning the string reversely.
@param [1] input string 
@param [2] separator
@param [3] recurse flag
@return the tail
@example $(tail "www.example.com" .) -> "com"
@example $(tail "www.example.com" . last) -> "example.com"
EOF

Str__tail() {
    if [ $# -ge 3 ] ; then
        echo "${1#*$2}" # with only one #, go to last separator in reverse order
    else
        echo "${1##*$2}" 
    fi
    return 0
}

:<<'EOF'
Same as Str__tail, except that the results in not echoed on stdout
but replaces the value of input variable itself passed as reference
@param [1] input string reference which will hold the tail as result
@param [2] separator
@param [3] recurse flag
EOF

Str__toTail() {
    local -n __toTailInRef=$1
    if [ $# -ge 3 ] ; then
        __toTailInRef="${__toTailInRef#*$2}" # with only one #, go to last separator in reverse order
    else
        __toTailInRef="${__toTailInRef##*$2}" 
    fi
    return 0
}


:<<'EOF'
Split the passed string in two parts according to the passed separator.
The first occurrence of the separator from the left is considered. 
@param [1] in input string reference which will hold the input string to split
@param [2] out resulting left part. If no separator found, the left part equals the input string
@param [3] in separator
@param [4] out resulting right part. If no separator found, the right is an empty string
@param [5] Optional (0 dflt): "1" or "0": indicates which string shall be empty in case no separator is found (0:left, 1:right part shall be empty): <0 erroneous arguments.
@return true (0) if the string could be split into 2 parts, false (1) otherwise (namely no separator found)
EOF

Str__split() {
    local in="$1"
    local -n out_left=$2
    local -n out_right=$4
    local emptyRule=$5
    out_right="${in#*$3}" # with only one #, go to last separator in reverse order
    out_left="${in%%$3*}"
    if [ $# -eq 4 ] ; then
        emptyRule=0
    else
        if ! Args__checkCount "${FUNCNAME[0]}" 5 "$#" ; then return -1 ; fi
        emptyRule=$5
    fi

    if [ "$out_right" == "$in" ] ; then # no separator found # && [ ${#out_right} == ${#out_left} ] ; then
    #if [ "$out_right" == "$out_left" ] && [ ${#out_right} == ${#out_left} ] ; then
        if [ $emptyRule -eq 0 ] ; then
            out_left=""
        elif [ $emptyRule -eq 1 ] ; then
            out_right=""
        else
    	    _log_err "${FUNCNAME[0]}: invalid 5th argument. It shall be 0 or 1."
            return -2
        fi
        return 1
    else
        return 0
    fi
}

:<<'EOF'
Replaces all occurences of a certain string with another.
Modifies the input string
@param [1] input string 
@param [2] substring to replace
@param [3] replacement substring 
@return updated input string
EOF

Str__replace() {
    if [ $# -eq 3 ] ; then
        local -n in=$1
        local oldSub="$2"
        local newSub="$3"
        in=${in//$2/$3} # with 1 slash, only one occurered
        return 0
    else
    	_log_err "${FUNCNAME[0]}: invalid use. at least 1 arg expected, $# passed ($*)"
        return 1
    fi
}

:<<'EOF'
Counts the number of occurences of a certain substring 
@param [1] input string 
@param [2] substring to count occurrences of
@print count
@return 0
EOF

Str__substringCount() {
    if [ $# -eq 2 ] ; then
        grep -o "$2" <<< "$1" | wc -l
    else
    	_log_err "${FUNCNAME[0]}: invalid use. 2 args expected, $# passed ($*)"
        return 1
    fi        
}

:<<'EOF'
If the passed string size exceeds a maximum size (maxlen) , it is truncated at right and 
truncated part is replaced with a replacement string
@param [1] inout reference to the input string to be truncated
@param [2] maximum output string length
@param [3] replacement for the shrinked data
EOF
Str__shrinkToRight() {
    local -n inout_string=$1
    local maxlen=$2
    local sep=$3
    local len=${#inout_string}
    local lensep=${#sep}

    if  [ $len -gt $lensep ] && [ $len -gt $maxlen ] ; then
            local leftSideLen=$(( ($maxlen - $lensep) ))
            inout_string="${inout_string:0:$leftSideLen}${sep}"
    fi
    return 0

}

:<<'EOF'
Shrinks the passed string to a string of a maximum size (maxlen) given in second argument.
The string is shrinked that both ends of the string is limited to maxlen/2, the remaining
being replaced with the specified replacement string.
@param [1] inout reference to the input string to be truncated
@param [2] maximum output string length
@param [3] replacement for the shrinked data
EOF
Str__shrinkToMid() {
    if ! Args__checkCount ${FUNCNAME[0]} 3 "$#" "Usage: <ref to string to shrink> <max output string length> <replacement for shrinked data>]"; then return 1; fi

    local -n inout_string=$1
    local maxlen=$2
    local sep=$3
    local len=${#inout_string}
    local lensep=${#sep}
    if [ $len -gt $(( 3 * $lensep )) ] && [ $len -gt $maxlen ] ; then
            #local leftSideLen=$(($len - $(( $lensep /2 )) ))
            local leftSideLen=$(( ($maxlen - $lensep) / 2 ))
            local rightSideLen=$leftSideLen
            if [ $(( (2*$leftSideLen) + $lensep )) -lt $len ] ; then
                    rightSideLen=$(( $rightSideLen + 1 ))
            fi
            #    _log_dbg "$leftSideLen $rightSideLen '$lensep' '$len' '$thriceSepLen' '$maxlen'"
            inout_string="${inout_string:0:$leftSideLen}${sep}${inout_string:$(($len-$rightSideLen)):$rightSideLen}"
    # else inout_string is unchanged
    fi
    return 0
}

:<<'EOF'
Str__toAsciiDocId
EOF
Str__toAsciiDocId()
{
    local -n __inout_inS=$1
    local __s="${__inout_inS}"
    Str__toLower __s
    __s="_${__s}"
    Str__replace __s "-" "_"
    Str__replace __s " " "_"
    Str__squeeze "${__s}" "${!__inout_inS}" "_"
}

# --------------------------------------------------------------------------------------
# Int API
# --------------------------------------------------------------------------------------
Int__isInt() {
    if [ -z "$1" ]  ; then
        return 1
    fi
    local intres="${1%%.*}"
    if [ -z "$intres" ] ; then
        return 1
    fi
    [[ "$intres" =~ ^[0-9]+$ ]]
}

# Convert a floating number to an integer
Int__Int() {
    local intres="${1%%.*}"
    if [ -z "$intres" ] ; then
        echo -n "0"
    else
        echo -n "$intres"
    fi
}

Int__Int_r() {
    local -n __out_int_int_result="$1"
    local intres="${__out_int_int_result%%.*}"
    if [ -z "$intres" ] ; then
        __out_int_int_result=0
    else
        __out_int_int_result="$intres"
    fi
}

Int__percentage()
{
    local -n __inout_percent=$1
    local originalPercentage="$__inout_percent"
    local percentVal=0
    local __value_for_percentage=$2
    Str__trimEnd "${__inout_percent}" percentVal "%"
    #_log_vars __inout_percent percentVal
    if [ "$__inout_percent" != "$percentVal" ] ; then 
        # We have a percentage value given
        Int__calc_r "($percentVal * ${__value_for_percentage})/100"  __inout_percent
        #_log "Int__percentage : $originalPercentage of ${__value_for_percentage} is ${__inout_percent}"        
    fi
    # else value is unchanged otherwise
}

Int__calc() {
    local precision=3
    local resFloat=$(echo "scale=$precision; $1"|bc)
	Int__Int $resFloat
}

Int__calc_r() {
    local -n __out_calc_result="$2"
    local precision=3
    #__out_calc_result=$(echo "scale=$precision; $1"|bc)
    read __out_calc_result< <(bc<<<"scale=$precision; $1")
	Int__Int_r ${!__out_calc_result}    
}


Int__withinRange() {
    local checkValue=$1
    local lowValue=$2
    local highValue=$3

    if ! Args__checkCount ${FUNCNAME[0]} 3 "$#" "Usage: <value to check> <low range value> <high range value>"; then return 1; fi
    #if ! Int__Int "$lowValue" ; then _log_err "${FUNCNAME[0]} first argument $lowValue not an integer" ; return 2 ; fi
    #if ! Int__Int "$highValue" ; then _log_err "${FUNCNAME[0]} second argument $highValue not an integer" ; return 3 ; fi
    #if ! Int__Int "$checkValue" ; then _log_err "${FUNCNAME[0]}  $checkValue not an integer" ; return 3 ; fi
    if [ $lowValue -gt $highValue ] ; then _log_err "${FUNCNAME[0]} [$lowValue,$highValue] invalid range." ; return 4 ; fi

    [ $checkValue -ge $lowValue ] && [ $checkValue -le $highValue ]
}

Int__series() {
    local cmd="local _i=0; for _i in {1..$1} ; do printf \"\${_i} \" ; done"
    if [ $1 -eq 0 ] ; then
        printf ""
    else
        eval "$cmd"
    fi
}

:<<'EOF'
Returns the maximum of the two passed integers
@param [1] first int
@param [2] second int
@param [3] ref to var for storing maximum values
EOF
Int__max()
{
    local leftOp=$1
    local rightOp=$2
    local -n out_max=$3
    if [ $leftOp -gt $rightOp ] ; then
            out_max=$leftOp 
    else
            out_max=$rightOp 
    fi
}

:<<'EOF'
Retrieves version numbers from a string of the form 'x[[.y].z]'
If a component is not define, there's an empty string
@param [1] out returned major version
@param [2] out returned minor version
@param [3] out returned update version
EOF

Int__readVersion()
{
    local ver="$1"
    local -n __inout_maj=$2
    local -n __inout_min=$3
    local -n __inout_upd=$4
    Str__split "$1" __inout_maj "." __inout_min 1
    if ! Int__isInt "$__inout_maj" ; then 
        _log_warn "'$__inout_maj' not a valid major number"
        return 1; 
    fi

    Str__split "$__inout_min" __inout_min "." __inout_upd 1
    if [ ! -z "$__inout_min" ] ; then
        if ! Int__isInt "$__inout_min" ; then 
            _log_warn "'$__inout_min' not a valid major number"
            return 1; 
        fi
    fi

    if [ ! -z "$__inout_upd" ] ; then
        if ! Int__isInt "$__inout_upd" ; then 
            _log_warn "'$__inout_upd' not a valid major number"
            return 1; 
        fi
    fi
    return 0
}

# --------------------------------------------------------------------------------------
# Float API
# --------------------------------------------------------------------------------------
Float__compare() {
    local expr="$1"
    local res
    read res< <(bc<<<"$1")
    if [ $res -eq 1 ] ; then 
        return 0;
    else
        return 1;
    fi
}

Float__calc() {
    local -n __out_flt_calc_result="$2"
    local precision=3
    if [ $# -eq 3 ] ; then 
        precision=$2 
    else
        if ! Args__checkCount ${FUNCNAME[0]} 2 "$#" "Usage: <math formula> <out variable>[<floating precision>]"; then return 1; fi
    fi
    read __out_flt_calc_result< <(bc<<<"scale=$precision; $1")
}

# --------------------------------------------------------------------------------------
# file size API
# --------------------------------------------------------------------------------------
Math__byteSize2ReadableSize() {
    if ! Args__checkCount ${FUNCNAME[0]} 3 "$#" "Usage: <size in bytes> <size type 0 or 1> <out variable>"; then return 1; fi
    local nbBytes=$1
    local sizeType="$2" # 0: multiple of 1000, 1 multiple of 1024
    local -n __out_hrSize="$3"

    local units
    local unitsValues
    if [ $sizeType -eq 0 ] ; then
        units=(Go Mo Ko o)
        unitsValues=(1000000000 1000000 1000 1)
    else
        units=(GiB MiB KiB o)
        unitsValues=(1073741824 1048576 1024 1)
    fi
    local cnt=0
    while [ $cnt -lt ${#units[@]} ] ; do
        if [ $nbBytes -ge ${unitsValues[$cnt]} ] ; then
            Int__calc_r "$nbBytes / ${unitsValues[$cnt]}" __out_hrSize
            __out_hrSize="${__out_hrSize} ${units[$cnt]}"
            return 0
        fi
        cnt=$(($cnt + 1))
    done        
    _log_warn "${FUNCNAME[0]}: invalide size '$nbBytes'"
    __out_hrSize=""
    return 1
}

Math__kbyteSize2ReadableSize() {
    if ! Args__checkCount ${FUNCNAME[0]} 3 "$#" "Usage: <size in bytes> <size type 0 or 1> <out variable>"; then return 1; fi
    local nbKiloBytes=$1
    local sizeType="$2" # 0: multiple of 1000, 1 multiple of 1024
    local -n __out_hrSize="$3"

    local units
    local unitsValues
    if [ $sizeType -eq 0 ] ; then
        units=(To Go Mo Ko)
        unitsValues=(1000000000 1000000 1000 1)
    else
        units=(TiB GiB MiB KiB)
        unitsValues=(1073741824 1048576 1024 1)
    fi
    local cnt=0
    while [ $cnt -lt ${#units[@]} ] ; do
        if [ $nbKiloBytes -ge ${unitsValues[$cnt]} ] ; then
            Int__calc_r "$nbKiloBytes / ${unitsValues[$cnt]}" __out_hrSize
            __out_hrSize="${__out_hrSize} ${units[$cnt]}"
            return 0
        fi
        cnt=$(($cnt + 1))
    done        
    _log_warn "${FUNCNAME[0]}: invalide size '$nbKiloBytes'"
    __out_hrSize=""
    return 1
}

:<<'EOF'
@param[2] scale: 0 size given is in byte, 1 size given is in kb, 2 size given is MB
EOF
Math__size2ReadableSize() {
    if ! Args__checkCount ${FUNCNAME[0]} 4 "$#" "Usage: <size> <size scale> <size type> <out variable>"; then return 1; fi
    local nbBytes=$1
    local sizeScale=$2
    local sizeType="$3" # 0: multiple of 1000, 1 multiple of 1024
    local -n __out_hrSize="$4"

    local units
    local unitsValues
    if [ $sizeType -eq 0 ] ; then
        units=(Po To Go Mo Ko o)
        unitsValues=(1000000000 1000000 1000 1)
    else
        units=(Pib TiB GiB MiB KiB o)
        unitsValues=(1073741824 1048576 1024 1)
    fi

    case $sizeScale in
        0)
            units=(${units[@]}:2)
        ;;
        1)
            units=(${units[@]}:1:4)
        ;;
        2)
            units=(${units[@]}:0:4)
        ;;
    esac

    local cnt=0
    while [ $cnt -lt ${#units[@]} ] ; do
        if [ $nbBytes -ge ${unitsValues[$cnt]} ] ; then
            Int__calc_r "$nbBytes / ${unitsValues[$cnt]}" __out_hrSize
            __out_hrSize="${__out_hrSize} ${units[$cnt]}"
            return 0
        fi
        cnt=$(($cnt + 1))
    done        
    _log_warn "${FUNCNAME[0]}: invalide size '$nbBytes'"
    __out_hrSize=""
    return 1
}

:<<'EOF'
@param[1] input size value
@param[2] input size value
EOF

Math__convertSizeToMiB() {
    if ! Args__checkCount ${FUNCNAME[0]} 3 "$#" "Usage: <size> <size scale> <out variable>"; then return 1; fi
    local size=$1
    local sizeScale=$2
    local -n __out_size="$3"
    local __out_size_converted

    Str__toLower sizeScale
    case "$sizeScale" in 
        t|tib)
            __out_size_converted=$(echo "1048576 * ${size}"|bc)
        ;;
        to|tb)
            local Mo_size=$(echo "1000000 * ${size}"|bc)            
            Math__convertSizeToMiB ${Mo_size} "Mo" __out_size_converted
        ;;
        g|gib)
            __out_size_converted=$(echo "1024 * ${size}"|bc)
        ;;
        go|gb)
            local Mo_size=$(echo "1000 * ${size}"|bc)         
            #echo "GO: ${Mo_size} "
            Math__convertSizeToMiB ${Mo_size} "Mo" "${!__out_size_converted}"
        ;;
        m|mib)
            # unchanged
            __out_size_converted=${size}
        ;;
        mo|mb)
            local Byte_size=$(echo "${size}*1000000"|bc)
            #echo "MO: ${Byte_size} "
            __out_size_converted=$(echo "${Byte_size}/1048576"|bc)
        ;;
        k|kib)
            __out_size_converted=$(echo "${size}/1024"|bc)
        ;;
        ko|kb)
            local Byte_size=$(echo "${size}*1000)")
            __out_size_converted=$(echo "${Byte_size}/1048576"|bc)
        ;;
        *)
            __out_size_converted=$(echo "${size}/1048576"|bc)
        ;;
    esac

    __out_size="${__out_size_converted}"
    #_log_dbg "SIZE IN MiB: '${__out_size}'"

}


# --------------------------------------------------------------------------------------
# Args API
# --------------------------------------------------------------------------------------

:<<'EOF'
This function can be conveniently used to check the number of arguments passed to a called function
@param [1] function name. This name shall be set by the calling function using ${FUNCNAME[0]}
@param [2] required number of arguments
@param [3] actual passed number of arguments
@param [4] extra message in case of mismatch
@return 0 when the args counts are matching, 1 otherwise. It is up to the calling function to determine whether it can go on its execution or interrupt
EOF

Args__checkCount() {
    local fn="$1"
    shift
    local requiredArgCount="$1"
    shift
    local actualArgCount="$1"
    shift
    local msg="$1"
    if [ "$requiredArgCount" != "$actualArgCount" ] ; then
	    _log_err "${fn}: passed $actualArgCount arguments, whereas $requiredArgCount expected. $msg"
	    return 1
    else
        return 0
    fi 
}

:<<'EOF'
This function can be conveniently used to check the minimum required number of arguments passed to a called function
@param [1] function name. This name shall be set by the calling function using ${FUNCNAME[0]}
@param [2] required of minimum number of arguments
@param [3] actual passed number of arguments
@param [4] extra message in case of mismatch
@return 0 when the args counts are matching, 1 otherwise. It is up to the calling function to determine whether it can go on its execution or interrupt
EOF

Args__checkMinCount() {
    local fn="$1"
    shift
    local requiredArgCount="$1"
    shift
    local actualArgCount="$1"
    shift
    local msg="$1"
    if [ "$requiredArgCount" -gt "$actualArgCount" ] ; then
	    _log_err "${fn}: passed $actualArgCount arguments, whereas at least $requiredArgCount expected. $msg"
	    return 1
    else
        return 0
    fi 
}
# --------------------------------------------------------------------------------------
# Array API
# --------------------------------------------------------------------------------------

:<<'EOF'
Tells whether an array contains a string equal to the passed value
@param [1] name of the array variable
@param [2] value string to search for in the array
@return 0 when found, 1 when not
EOF

Array__contains() {
    if ! Args__checkCount ${FUNCNAME[0]} 2 "$#" "Usage: <array var name> <value>."; then return 1; fi

    local -n arr=$1
    local val="$2"
    local item
    for item in "${arr[@]}"
    do
        if [ "$val" == "$item" ] ; then
            return 0
        fi
    done
    return 1
}


:<<'EOF'
Same as Array__contains, except that the array is past in the form of a string
where items are separated with a space. The function reconstructs a builtin array
from the string.
@param [1] string where array values are separated with a space
@param [2] value string to search for in the array
@return 0 when found, 1 when not
EOF

Array__contains_by_string() {
    if ! Args__checkCount ${FUNCNAME[0]} 2 "$#" "Usage: <string> <value>."; then return 1; fi

    local arr=($1)
    local val="$2"
    local item
    for item in "${arr[@]}"
    do
        if [ "$val" == "$item" ] ; then
            return 0
        fi
    done
    return 1
}
# --------------------------------------------------------------------------------------
# Input API
# --------------------------------------------------------------------------------------

:<<'EOF'
Echoes the value of the forced input, without removing it from the stack.
Returns 1 when nothing is available, 0 otherwise.
EOF

Input____forced_input=()
Input__getForcedInput()
{
    local -n out_forcedInput=$1
    local size=${#Input____forced_input[@]} 
    if [ $size -gt 0 ] ; then
        out_forcedInput="${Input____forced_input[$(( $size - 1 ))]}"
        return 0
    else
        return 1
    fi
}

:<<'EOF'
Push on the stack a forced input, i.e. a predefined answer for any Input__ function
EOF

Input__pushForcedInput()
{
    Input____forced_input+=("$1")
    return 0
}

:<<'EOF'
Removes a forced input from the head of the stack.

NOTE: this function shall not be called from a subshell (using $(..)), since this
creates a subshell process, whereby the original Input____forced_input is not modifed.
EOF

Input__popForcedInput()
{
    local size=${#Input____forced_input[@]} 
    if [ $size -gt 0 ] ; then
        local newsize=$(( $size - 1 ))
        local val="${Input____forced_input[$newsize]}"
        if [ $newsize -gt 0 ] ; then
            Input____forced_input=(${Input____forced_input[@]:0:$newsize})
        else
            Input____forced_input=()
        fi
        return 0
    fi
    return 1
}

Input__clearForcedInput()
{
    Input____forced_input=()
}

Input__timeoutKeystroke() {
    if ! Args__checkCount ${FUNCNAME[0]} 3 "$#" "Usage: <text> <number of seconds> [<text>]"; then return 1; fi

    local secsAsString="$2"
    local secsLen=${#secsAsString}
    local prefix="$1"
    local secs=$2
    local suffix="$3"
    local pid
    local userKey
    while [ $secs -gt 0 ]; do
        printf "\r"
        read -t 1 -n 1 -p "${prefix}${secs}${suffix}" userKey 
        if [ $? -eq 0 ] ; then 
            break;
        fi
        secs=$(($secs - 1))
    done
    echo
}

:<<'EOF'
Prompts for a password
@param [1] reference to the variable where password will be saved.
EOF
Input__password() {
    local -n __out_password="$1"
    read -s -r -p "Enter password: " __out_password 2>&1
    Str__seq '*' ${#__out_password}
    echo
    #_log_dbg "${#__out_password} '${__out_password}'"
}


:<<'EOF'
Prompts for a confirmation among the following : y,Y,n,yes,YES,no,NO
Default prompt 'y/n' is automatically appended to the question by default.
@param [1] question sentence
@param [2] optional default answer if nothing entered.
@param [3] optional alternative prompt
@return 0 upon positive confirmation, 1 otherwise
Question is asked until a valid answer is given.
EOF

Input__confirm() {
    local question="$1"
    local default=""
    local prompt="y/n"
    local answer=""
    if [ $# -ge 2 ] ; then
        prompt=$2
    fi
    if [ $# -ge 3 ] ; then
        default=$3
    fi
    if [ $# -gt 3 ] ; then
        _log_warn "${FUNCNAME[0]}: too much arguments specified"
    fi
    
    local __forcedInput
    Input__getForcedInput __forcedInput
    Str__toLower __forcedInput
    if [ "${__forcedInput}" == "y" ] ; then
        return 0
    fi
    if [ "${__forcedInput}" == "n" ] ; then
        return 1
    fi

    while true; do
        Term__eraseCurrentLine
        read -n1 -s -r -p "$question [$prompt] " answer 2>&1

        if [ -z "$answer" ]; then
            answer=$default
        fi
        Str__toLower answer
        case "$answer" in
            y|yes) return 0;; 
            n|no) return 1;;
            *) ;;
        esac
    done
    return 0
}

:<<'EOF'
Prompts for a memory size among the following : xG, xM, xK
respectively x Gibibytes (GiB), x Mebibytes (MiB), x kibibytes (KiB)
Default prompt 'int followed by G/M/K or a to abort' is automatically appended to the question by default.
@param [1] question sentence
@param [2] result size is stored in this parameter
@param [3] unit of the returned memsize
@param [4] bool telling whether to abort an invalid memory size input
@return 0 upon positive entry,
@output memsize in octets except if param 4 is specified
Question is asked until a valid answer is given.
EOF

Input__memsize() {
    local question="$1"
    local prompt="int followed by T/G/M/K or 'a' to abort"
    local answer=""
    local -n __memsize=$2
    local -n __unit=$3
    local abortOnBadInput=false

    if [ $# -eq 4 ] ; then
        abortOnBadInput=$4
    fi

    if [ $# -ge 5 ] ; then
        _log_warn "${FUNCNAME[0]}: too much arguments specified"
    fi

    Term__reset # Ensure cursor is visible

    while true; do
        local __forcedInput
        Input__getForcedInput __forcedInput
        Str__toLower __forcedInput

        if [ ! -z "${__forcedInput}" ] ; then
            answer="${__forcedInput}"
            Input__popForcedInput
        else
            read -p "$question [$prompt] " answer 
        fi    

        Str__toLower answer
        local unit
        Str__last "$answer" unit
        local input_memsize
        Str__trimEnd "$answer" input_memsize "$unit"

        if [ $# -eq 4 ] ; then
            __memsize=$input_memsize
            __unit=$unit
        fi

        if [ "$answer" == "a" ] ; then return 1; fi

        # Let continue execution to check last char (unit)

        case "$unit" in
            k|kib) 
                if [ $# -eq 3 ] ; then
                    __memsize=$(( $input_memsize * 1024 )); 
                    __unit="O"
                fi
                return 0
                ;;
            m|mib) 
                if [ $# -eq 3 ] ; then
                    __memsize=$(( $input_memsize * 1024 * 1024 )); 
                    __unit="O"
                fi
                return 0
                ;;
            g|gib) 
                if [ $# -eq 3 ] ; then
                    __memsize=$(( $input_memsize * 1024 * 1024 * 1024 )); 
                    __unit="O"
                fi
                return 0
                ;; 
            t|tib) 
                if [ $# -eq 3 ] ; then
                    __memsize=$(( $input_memsize * 1024 * 1024 * 1024 * 1024 )); 
                    __unit="O"
                fi
                return 0
                ;;
            *)
            if $abortOnBadInput; then 
                _log_err "Bad memory size '${__memsize}${__unit}'. Must be an integer followed by T/G/M/K"
                return 1
            fi
             # retry
            ;;
        esac
    done
    return 1
}

:<<'EOF'
Prompts for a file system path. If it does not 
@param [1] question sentence
@param [2] default proposed path
@param [3] flag telling to create folder if does not exist. 0: do create but confirm, 1: do create but no confirm, do not create otherwise
@param [4] path is stored in this parameter
@return 0 upon positive entry,
@output valid file path 
Question is asked until a valid answer is given.
EOF

Input__dirpath() {
    local question="$1"
    local prompt="<enter>=default, <a>bort"
    local default="$2"
    local createFolder="$3"
    local answer=""
    local -n __filepath=$4
    local forceDefaultInput=1

    if ! Args__checkCount "${FUNCNAME[0]}" 4 "$#" ; then return -1 ; fi

    Term__reset # Ensure cursor is visible

    local __forcedInput
    Input__getForcedInput __forcedInput
    Str__toLower __forcedInput

    case "${__forcedInput}" in
        y|yes) forceDefaultInput=0 ;;
        *) forceDefaultInput=1 ;; 
    esac

    while true; do
        if [ $forceDefaultInput -ne 0 ] ; then
            read -e -p "$question (default:'$(realpath -m "$default")') [$prompt] " answer 
        fi    

        if [ "$answer" == "a" ] ; then return 1; fi

        if [ -z "$answer" ] ; then
            answer="$default"
        fi

        if [ -e "$answer" ] ; then
           if [ -d "$answer" ] ; then
                __filepath=$(realpath -m "$answer")
                return 0
            else
                _log_warn "$answer exists but is not a directory"
            fi
        elif [ $createFolder -eq 2 ]  ; then
                # Do not create
                __filepath=$(realpath -m "$answer")
                return 0
        elif [ $createFolder -eq 1 ]  ; then
                __filepath=$(realpath -m "$answer")
                if mkdir -p "$answer" &>/dev/null; then
                    return 0
                else
                    printf "Folder creation failed!\n"
                fi
        elif [ $createFolder -eq 0 ]  ; then
            local confirmCreate=1
            if [ $forceDefaultInput -eq 0 ] ; then
                Input__popForcedInput
                confirmCreate=0
            else
                Input__confirm "Do you want to create $answer?"                                
                confirmCreate=$?
            fi
            
            if [ $confirmCreate -eq 0 ] ; then
                __filepath=$(realpath -m "$answer")
                #echo "creating folder ${__filepath}"
                if mkdir -p "$answer" &>/dev/null; then
                    return 0
                else
                    printf "Folder creation failed!\n"
                fi
            fi
        fi
    done
    return 1
}


Input__sentence() {
    local question="$1"
    local default="$2"
    local prompt="<enter>=default"
    local answer=""
    local -n out_word=$3
    local forceDefaultInput=1

    Term__reset # Ensure cursor is visible

    if ! Args__checkMinCount "${FUNCNAME[0]}" 3 "$#" ; then return -1 ; fi

    local __forcedInput
    Input__getForcedInput __forcedInput
    Str__toLower __forcedInput

    case "${__forcedInput}" in
        y|yes) forceDefaultInput=0 ;;
        *) forceDefaultInput=1 ;; 
    esac

    #if Input__getForcedInput out_word &>/dev/null;  then
    #    return 0
    #fi

    while true; do
        Term__eraseCurrentLine        

        if [ $forceDefaultInput -ne 0 ] ; then
            if [ -z "$default" ] ; then
                read  -ep "$question ('a' to abort): " answer 
            else
                read  -ep "$question (default:'$default', 'a' to abort) [$prompt]: " answer 
            fi
            printf '\033[A'
        fi

        if [ "$answer" == "a" ] ; then return 1; fi

        if [ -z "$answer" ] ; then
            if [ -z "$default" ] ; then
                continue
            else
                answer="$default"
            fi
        fi

        local pat="^.*$"
        if [ $# -ge 4 ] ; then
            pat="$4"
        fi

        if [[ ! "$answer" =~ $pat ]] ; then
            continue
        else
            out_word="$answer"
            printf "\n"
            break
        fi
    done
    return 0
}


:<<'EOF'
Prompts for a word, i.e. a sequence of alphanumeric letter plus other chars like _,- and .
@param [1] question sentence
@param [2] default value
@param [3] word is stored in this parameter
@param [4] option Accepted input pattern
@return 0 upon positive entry,
@output valid word
Question is asked until a valid answer is given.
EOF

Input__Word() {
    local question="$1"
    local default="$2"
    local prompt="<enter>=default"
    local answer=""
    local -n out_word=$3
    local forceDefaultInput=1

    Term__reset # Ensure cursor is visible

    if ! Args__checkMinCount "${FUNCNAME[0]}" 3 "$#" ; then return -1 ; fi

    local __forcedInput
    Input__getForcedInput __forcedInput
    Str__toLower __forcedInput

    case "${__forcedInput}" in
        y|yes) forceDefaultInput=0 ;;
        *) forceDefaultInput=1 ;; 
    esac

    #if Input__getForcedInput out_word &>/dev/null;  then
    #    return 0
    #fi

    while true; do
        Term__eraseCurrentLine        

        if [ $forceDefaultInput -ne 0 ] ; then
            if [ -z "$default" ] ; then
                read  -ep "$question " answer 
            else
                read  -ep "$question (default:'$default') [$prompt] " answer 
            fi
            printf '\033[A'
        fi

        if [ -z "$answer" ] ; then
            if [ -z "$default" ] ; then
                continue
            else
                answer="$default"
            fi
        fi

        local pat="^([\.a-zA-Z0-9_-])*$"
        if [ $# -ge 4 ] ; then
            pat="$4"
        fi

        if [[ ! "$answer" =~ $pat ]] ; then
            #_log "PATTERN FAILED for '$answer'" 
            continue
        else
            out_word="$answer"
            printf "\n"
            break
        fi
    done
    return 0
}



Input__escapeChar=$(printf "\u1b")

:<<'EOF'
Prompts for a menu selection via a cursor according to a maximum number of entries. 
The current selected line is in reverse video.

The display of the menu, the highlighted selection and the prompt can either be taken over 
by this function or from an external callback function passed when the 4th parameter is specified.

If this function takes over all display, a specific prompt can be passed on to the fifth parameter.
The default prompt is the 'up/down arrow' unicode char, the 'home key' unicode char, the 'end key'
unicode char, the 'enter' unicode char and finally '<q>uit', which corresponds to the keys which are
always handled by default.

Additional key handlings can be specified in 6th parameter.

Therefore, the key handling and matching returned values are as follows:
 - 0 is returned when quitting the menu. 
 - the selected index is returned on <enter>
-  When an additional key as specified in the 6th parameter is stroke, 
   the matching interpreted numeric value is returned.

The 7th parameter enables to specify indexes of items of the list which shall never be selectable. When moving
selection on the list, the cursor will jump over them.

The 8th parameter enables to specify a call back function which will be called every second when no
input is performed.

@param [1] Menu lines
@param [2] Question sentence
@param [3] Index of initial selected value
@param [4] Optional, display function to call to update display status of the list after navigation. 
           This function has the full charge of performing display, including display of current item in reverse video
@param [5] Optional, prompt. it shall be a list of space-separated strings/chars
@return the index of selected item starting from 1, or 0 on quit
@param [6] Optional, list of coma separated additional key actions and their id of the form <char>:<id>
@param [7] List of index to ignore for selection
@param [8] time out callbacks
EOF

#Input__cursorSelect_pageStep=5
# Policies
# 0: Go to the very beginning or the very end
# 1: Go to the next ignored index
#Input__cursorSelectPolicy=0

Input__cursorSelect() {
    local menuLines="$1"
    local question="$2"
    local prompt=('\U21F5' '\U21F1' '\U21F2' '\U23CE' '<q>uit')
    local nbItems="$(echo "$menuLines"|wc -l)"
    local defaultSelectIndex=$3
    local currentSelectIndex=$3
    local displayFunction=""
    local timeoutCallback=""
    local timeoutTimer=0
    local forceInput=1
    local answer=""
    local prevAnswer=""
    declare -A additionalKeyActions
    declare -A ignoredIndexMap
    local currentPageIndex=0 # will be computed

    if [ $# -ge 7 ] ; then 
        local ignoredIndexArray=($7)
        local ignIdx
        for ignIdx in "${ignoredIndexArray[@]}" ; do ignoredIndexMap[$ignIdx]="yes" ;  done
    fi

    if [ $# -ge 4 ] ; then 
        displayFunction="$4"
        if ! Env__fn_exists "${displayFunction}" ; then
            _log_err "${FUNCNAME[0]}: $displayFunction is not a valid display function. Ignored."
            displayFunction=""
        fi
    fi

    if [ $# -ge 5 ] ; then
        if [ ! -z "$5" ] ; then prompt=($5) ; fi
    fi

#_log_dbg "keyconfig: '$6'"
    if [ $# -ge 6 ] ; then 
        local actions=()
        local i=0
        readarray -t -d',' actions <<< "$6"
        while [ $i -lt ${#actions[@]} ]
        do
              local actionFields=()
              readarray -t -d':' actionFields <<< "${actions[$i]}"
              local action="${actionFields[1]}"
              Str__trimEnd "$action" action
              #_log_dbg "action field '${actionFields[0]}' = 'action'"
              additionalKeyActions[${actionFields[0]}]="$action"
              i=$(($i + 1))                
        done
    fi

    if [ $# -ge 8 ] ; then 
        timeoutCallback=""
        timeoutTimer=0
        timeoutCallbackData=($8)
        if [ ${#timeoutCallbackData[@]} -ne 2 ]  ; then
            _log_err "${FUNCNAME[0]}: invalid usage. '$timeoutCallbackData' is not a valid (callback function,time) couple. Ignored."
        elif ! Env__fn_exists "${timeoutCallbackData[0]}" ; then
            _log_err "${FUNCNAME[0]}: '${timeoutCallbackData[0]}' is not a valid timeout callback function. Ignored."
        else
            timeoutCallback="${timeoutCallbackData[0]}"
            timeoutTimer=${timeoutCallbackData[1]}
        fi
    fi

    if [ $3 -eq 0 ] ; then
        _log_warn "${FUNCNAME[0]}: default index must start from 1. Assuming 1 instead of 0."
        defaultSelectIndex=1
        currentSelectIndex=1
    fi
    if [ $3 -gt $nbItems ] ; then
        _log_warn "${FUNCNAME[0]}: default index is greater than number of menu lines. Assuming last item."
        defaultSelectIndex=$nbItems
        currentSelectIndex=$nbItems
    fi


    if [ $# -gt 8 ] ; then
        _log_err "${FUNCNAME[0]}: too much arguments specified"
    fi

    # Handle the initial index and check if on ignored one!
    Input__cursorSelect_manageIgnoreIndex '[A' currentSelectIndex ignoredIndexMap

    Term__maskCursor
    
    if [ ! -z "$question" ] ; then
        echo -e "$question"
    fi

    local termNbRows
    Term__rows termNbRows
    termNbRows=$(($termNbRows - 3 )) # Reserve a line for the menu prompt
    local nbPages=$(( $nbItems / $termNbRows ))
    if [ $(( ($nbItems % $termNbRows) )) -ne 0 ] ; then
        nbPages=$(( $nbPages + 1))
    fi
    currentPageIndex=$(( ($currentSelectIndex-1) / $termNbRows )) # counts from 0
    local nbItemsPerPage=$nbItems
    if [ $nbPages -gt 1 ] ; then nbItemsPerPage=$termNbRows; fi


    while true; do
#echo "'$termNbRows' '$nbItems', nbPages=$nbPages, currentPageIndex=$currentPageIndex, currentSelectIndex=$currentSelectIndex " >>"${__LOG_ERR_FILE__}" 
        # Print the menu with selected item
        local cnt=1
        if [ ! -z "$displayFunction" ] ; then
            eval $displayFunction $currentSelectIndex
        else
            printf '\033[s'
            while IFS= read -s -r line 
            do
                    local testIndex
                    testIndex=$(( ${currentPageIndex}*${termNbRows} + $currentSelectIndex ))
                    if [ $cnt -gt $(( ${currentPageIndex}*${termNbRows} )) ]  && 
                       [ $cnt -le $(( ${currentPageIndex}*${termNbRows} + $termNbRows)) ]  ; then
                        Term__eraseCurrentLine                       
                        Str__trimOnce "$line" line "'"
                        #line="${line#\'}"
                        #line="${line%\'}"
                        if [ $(( $cnt - ( ${currentPageIndex}*${termNbRows}) )) -eq $currentSelectIndex ] ; then
                            printf '\033[7m'
                            printf "${line}\033[0m\n"
                        else
                            printf "${line}\n"
                        fi
                    fi
                    cnt=$((cnt + 1))
            done <<< "$menuLines"
            # Clear remaining lines on the last pages
            if [ $nbPages -gt 1 ] && [ $currentPageIndex -eq $((nbPages -1 )) ] ; then
                local nbItemLastPage=$(( ${nbItems} % ${termNbRows} ))
                local nbRemainingLastPage=$(( ${termNbRows} - ${nbItemLastPage} ))
#echo "'nbRemaining to clear=$nbRemainingLastPage " >>"${__LOG_ERR_FILE__}" 
                if  [ $nbItemLastPage -ne 0 ]  ; then
                    while [ $cnt -le $(($nbItems + $nbRemainingLastPage)) ] ; do
                            Term__eraseCurrentLine                       
                            printf "\n"
                            cnt=$((cnt + 1))
                    done
                fi
            fi
        fi

        local readRet=129

        # Timed-out input read loop
        prevAnswer="$answer"
        while [ $readRet -gt 128 ] 
        do
            local __forcedInput
            Input__getForcedInput __forcedInput

            if [ ! -z "${__forcedInput}" ] ; then
                answer="${__forcedInput}"
                Input__popForcedInput
            else
                if [ -z "$displayFunction" ] ; then
                    local p
                    for p in "${prompt[@]}" ; do printf $p ; printf " " ; done
                fi
                if [ -z "${timeoutCallback}" ] ; then
                    read -n1 -r answer
                    readRet=$?
                else
                    read -t $timeoutTimer -n1 -r answer
                    readRet=$?
                fi

    #_log "has read '$answer'" >&2
                if [[ $answer == ${Input__escapeChar} ]]; then
    #_log "espace FOUND read '$answer'" >&2
                        read -rsn2 answer &>/dev/null # read 2 more chars
                fi
            fi
            
            if [ $readRet -gt 128 ] ; then 
                if [ ! -z "${timeoutCallback}" ] ; then
                    eval "${timeoutCallback}"
                    callbackRet=$?
                    if [ $callbackRet -ne 0 ] ; then 
                        return $callbackRet
                    else
                        continue
                    fi
                fi
            fi
        done

        # Handle valid input
        # NOTE: use 'showkey -a' to get the key string
        #  printf '\033[u'  is to rewind cursorve to saved position with '\033[s'

        #Term__clear 
        #printf "key press: '%s'\n" "$answer"
        #continue
        #exit 0
        if [ $readRet -eq 0 ] ; then 
            case $answer  in
            'q') Term__reset; return 0;;
            # Previous index
            '[A') printf '\033[u' ; 
                if [ $currentSelectIndex -gt 1 ] ; then
                    currentSelectIndex=$(($currentSelectIndex-1)); 
                elif [ $currentPageIndex -gt 0 ] ; then
                    currentPageIndex=$(($currentPageIndex - 1))
                    currentSelectIndex=$termNbRows
                fi 
                ;;
            # Next index
            '[B') printf '\033[u' ; 
                if [ $currentSelectIndex -lt $nbItemsPerPage ] ; then 
                    currentSelectIndex=$(($currentSelectIndex+1)) ; 
                elif [ $currentPageIndex -lt $(($nbPages-1)) ] ; then
                    currentPageIndex=$(($currentPageIndex + 1))
                    currentSelectIndex=1
                fi
                ;;
            # Home key
            '[H') 
                # First item (home key)
                printf '\033[u' ; 
                currentPageIndex=0;
                currentSelectIndex=1; 
                ;;
            # End key
            '[F')  
                # Last item (End key)
                printf '\033[u' ; 
                currentPageIndex=$(($nbPages - 1))
                currentSelectIndex=$(( ${nbItems} % ${termNbRows} ))  ; 
                if [ $currentSelectIndex -eq 0 ] ; then
                    currentSelectIndex=${nbItemsPerPage}
                fi
                ;;
            #'[5~') printf '\033[u' ; currentSelectIndex=1; ;;
            #'[6~') printf '\033[u' ; currentSelectIndex=$nbItems; ;;
            '~') 
                if [ "$prevAnswer" = '[5' ] ; then 
                    # Prev page / page up
                    printf '\033[u' ;  

                    local indexCorrectedByIgnoreIndex=0
                    Input__cursorSelect_findFirstIgnoreIndexOnCurrentPage $currentPageIndex $currentSelectIndex true $termNbRows ignoredIndexArray indexCorrectedByIgnoreIndex
                    if [ $indexCorrectedByIgnoreIndex -ne 0 ] ; then
                            currentSelectIndex=$indexCorrectedByIgnoreIndex
                    else
                        if [ $currentPageIndex -gt 0 ] ; then
                            currentPageIndex=$(($currentPageIndex - 1))
                            currentSelectIndex=$termNbRows
                        else
                            currentSelectIndex=1; 
                        fi 
                    fi
                fi
                if [ "$prevAnswer" = '[6' ] ; then 
                    # Next page / page down
                    printf '\033[u' ;  

                    local indexCorrectedByIgnoreIndex=0
                    Input__cursorSelect_findFirstIgnoreIndexOnCurrentPage $currentPageIndex $currentSelectIndex false $termNbRows ignoredIndexArray indexCorrectedByIgnoreIndex
                    if [ $indexCorrectedByIgnoreIndex -ne 0 ] ; then
                            currentSelectIndex=$indexCorrectedByIgnoreIndex
                    else
                        if [ $currentPageIndex -lt $(($nbPages-1)) ]; then
                            currentPageIndex=$(($currentPageIndex + 1))
                            currentSelectIndex=1
                        else
                            currentSelectIndex=$(( ${nbItems} % ${termNbRows} ))  ; 
                            if [ $currentSelectIndex -eq 0 ] ; then
                                currentSelectIndex=${nbItemsPerPage}
                            fi
                        fi
                    fi
                fi
                ;;
            #'[D') # left
            #'[C') # right
            $'\0') 
#echo "'return \0 ??  $(( (${currentPageIndex} * ${nbItemsPerPage}) + $currentSelectIndex ))" >>"${__LOG_ERR_FILE__}" 

                return $(( (${currentPageIndex} * ${nbItemsPerPage}) + $currentSelectIndex ))
                ;;
            '[5'|'[6') 
                    # Possible page down/up  
                    printf '\033[u' ;          
                ;;
            *) 
                local keyAction=${additionalKeyActions[$answer]}
                if [ ! -z "${keyAction}" ] ; then        
                    if Int__isInt ${keyAction} ; then
                        return ${keyAction}
                    else
                        Str__replace keyAction '\?' $(( (${currentPageIndex} * ${nbItemsPerPage}) + $currentSelectIndex ))
                        local ret="$(( ${keyAction} ))"

                        return $ret
                    fi
                else
                    #printf '\033[f' # move cursor to the top INITIAL: correct ???
                    printf '\033[u' ; # NEW 21/7/25
                fi
                ;;
            esac        

            Input__cursorSelect_manageIgnoreIndex "$answer" currentSelectIndex ignoredIndexMap
            #_log_dbg "NEW index selection '$currentSelectIndex'"
        fi
done
    return 1
}

:<<'EOF'
This function is intended to be called after an update of the current index, 
to determine whether the new index is pointing to an index to be ignored.
Depending on the previous navigation action (up or downwards the list), the current index
is corrected to avoid an ignore index and shifted resp. one step up or down in the list.
NOTE: It does not not yet handle the case of successive ignored lines, for which it may have to
be called recursively

@param [1] last user navigation action (key sequence). 
@param [2] updated index
@param [3] map of ignored index
EOF
Input__cursorSelect_manageIgnoreIndex() 
{
    local answer="$1" # last user navigation
    local -n out_currentIndex=$2
    local -n in_ignoredIndexMap=$3
    if [ ${#in_ignoredIndexMap[$currentSelectIndex]} != 0 ] ; then
#_log_dbg "ignoring index selection '$currentSelectIndex'" 
        case "$answer"  in
        '[A'|'[H')  
            # we were going up
            if [ $currentSelectIndex -gt 1 ] ; then 
                currentSelectIndex=$(($currentSelectIndex-1)) ; 
            else
                currentSelectIndex=$(($currentSelectIndex+1)) ;
            fi
            Input__cursorSelect_manageIgnoreIndex "$answer" "${!out_currentIndex}" "${!in_ignoredIndexMap}"
            ;; 
        '[B'|'[F')   
            # we were going down the list
            if [ $currentSelectIndex -lt $nbItems ] ; then 
                currentSelectIndex=$(($currentSelectIndex+1)) ; 
            else
                currentSelectIndex=$(($currentSelectIndex-1)) ;
            fi
            Input__cursorSelect_manageIgnoreIndex "$answer" "${!out_currentIndex}" "${!in_ignoredIndexMap}"
            ;;
        esac
    fi      

    return 0
}

:<<'EOF'
This function is intended to be called before a page jump to determine whether
there's an ignore ahead when jumping forward (down) or one before current index 
when jumping backward (up). If so 

@param [1] current page index 
@param [2] current index in current page (relative index)
@param [3] page jump direction : true if up, false if down
@param [4] Number of items that can be displayed on one terminal page
@param [5] The map of 'ignore index'
@param [6] Found ignore index on the way to the page jump
EOF

Input__cursorSelect_findFirstIgnoreIndexOnCurrentPage() 
{
    local _in_currentPageIndex=$1
    local _in_currentIndex=$2
    local _inPageUp=$3
    local _in_termNbRows=$4
    local -n _in_ignoredIndexMap=$5
    local -n _out_newCurrentIndexAtIgnoreIndex=$6

    local absoluteIndexStepInOnPage=$(( ${_in_currentPageIndex}*${_in_termNbRows} ))
    local absoluteIndexFirstOnPage=$(( ${absoluteIndexStepInOnPage} + 1 ))
    local absoluteIndexCurrentSelection=$(( ${absoluteIndexStepInOnPage} + ${_in_currentIndex} ))
    local absoluteIndexLastOnPage=$(( ${absoluteIndexStepInOnPage} + $termNbRows ))

    #_log_vars absoluteIndexStepInOnPage absoluteIndexFirstOnPage  absoluteIndexCurrentSelection absoluteIndexLastOnPage
    #_log "_in_ignoredIndexMap: ${_in_ignoredIndexMap[@]}" >> ${__LOG_ERR_FILE__}
    local newAbsoluteCurrentIndex=0
    local ignoreIndex=0
    for ignoreIndex in "${_in_ignoredIndexMap[@]}" ; do
    #_log_vars _inPageUp ignoreIndex  newAbsoluteCurrentIndex
        local updateFoundIndex=false
        if ${_inPageUp} ; then        
            if [ $ignoreIndex -ge $absoluteIndexFirstOnPage ] && [ $ignoreIndex -lt $absoluteIndexCurrentSelection ] ; then
                # Take the closest one when jumping backwards
                if [ ${newAbsoluteCurrentIndex} -eq 0 ] || [ $ignoreIndex -gt ${newAbsoluteCurrentIndex} ] ; then
                    newAbsoluteCurrentIndex=$(( $ignoreIndex + 1))
                    if [ $newAbsoluteCurrentIndex -eq $absoluteIndexCurrentSelection ] ; then
                        newAbsoluteCurrentIndex=0
                    else
                        # Keep newAbsoluteCurrentIndex for the next round    
                        # and compute the relative index     
                        _out_newCurrentIndexAtIgnoreIndex=$((${newAbsoluteCurrentIndex} % ${_in_termNbRows}))
                    fi
                fi                
            fi
        else
            if [ $ignoreIndex -gt $absoluteIndexCurrentSelection ] && [ $ignoreIndex -le $absoluteIndexLastOnPage ] ; then
                # Take the closest one when jumping forwards
                if [ ${newAbsoluteCurrentIndex} -eq 0 ] ||  [ $ignoreIndex -lt ${newAbsoluteCurrentIndex} ] ; then
                    newAbsoluteCurrentIndex=$(( $ignoreIndex - 1))
                    if [ $newAbsoluteCurrentIndex -eq $absoluteIndexCurrentSelection ] ; then
                        newAbsoluteCurrentIndex=0                 
                    else
                        # Keep newAbsoluteCurrentIndex for the next round    
                        # and compute the relative index     
                        _out_newCurrentIndexAtIgnoreIndex=$((${newAbsoluteCurrentIndex} % ${_in_termNbRows}))
                    fi
                fi                
            fi
        fi
    done
    #_log_vars newAbsoluteCurrentIndex _out_newCurrentIndexAtIgnoreIndex

}

# --------------------------------------------------------------------------------------
# File API
# --------------------------------------------------------------------------------------

:<<'EOF'
Returns the base file name (with its extension) of the passed file name
@param [1] filename
@param [2] out returned file basename
EOF

File__basename() {
    local filename="$1"
    local -n out_corename=$2

    local basename=${filename##*/}
    out_corename="$basename"
    return 0
}


:<<'EOF'
Returns the dirname of the passed file path. The path is assumed to be an absolute path
without . or .. components.
@param [1] filepath
@param [2] out returned file basename
EOF

File__dirname() {
    local filepath="$1"
    local -n out_dirname=$2

    Str__trimEnd "$filepath" filepath "/"
    local dirname=${filepath%/*}
    if [ -z "$dirname" ] ; then 
        dirname="/" 
    fi
    out_dirname="$dirname"
    return 0
}


:<<'EOF'
Returns the core file name (without its extension) of the passed file name
@param [1] filename
@param [2] out returned file corename
EOF

File__corename() {
    local filename="$1"
    local -n out_corename=$2
    #Str__head "$(basename "$1")" "." last

    local basename=${filename##*/}
    local basenameNoExt=${basename%.*}
    out_corename="$basenameNoExt"
    return 0
}

:<<'EOF'
Returns the file extension of the passed file name
EOF

File__ext() {
    local filename="$1"
    local -n out_extension=$2

    local tail=${filename##*.}
    
    if [ "$tail" == "$filename" ] ; then
        out_extension="" # the file did not have an extension
    else
        out_extension="$tail"
    fi
    return 0
}

:<<'EOF'
Returns the file path with extension 
EOF

File__noext() {
    local filename="$1"
    local -n out_pathNoExt=$2

    out_pathNoExt=${filename%.*}
    return 0
}

:<<'EOF'
Performs a mirror copy of folders contained within the passed source folder path 
to the specified target folder.
The operation uses the function File__mirrorCopy.

@param [1] in parent folder
@param [2] in destination folder
@param [3] in optional a space-separated list of exclude patterns for folders to be excluded and not copied.
EOF

File__copyDirs() 
{
    local __in_srcFolder="$1"
    local __in_dstFolder="$2"
    local __in_excludedDirs
    local tmpFile=""

    if [ ! -d "${__in_srcFolder}" ] ; then
        _log_err "${FUNCNAME[0]}: '${__in_srcFolder}' is an invalid source directory."
        return 1
    fi

    if [ ! -d "${__in_dstFolder}" ] ; then
        _log_err "${FUNCNAME[0]}: '${__in_dstFolder}' is an invalid destination directory."
        return 1
    fi

    if [ $# -ge 3 ] ; then
        tmpFile=$(mktemp) # Create the exclusion file to be passed to the mirrorCopy
        __in_excludedDirs="$3"
        local excludedDir
        (
        set -f            
        for excludedDir in $__in_excludedDirs ; do
            echo "${excludedDir}" >> "${tmpFile}"
        done
        )
    fi

    local subdir
    for subdir in "${__in_srcFolder}"/* 
    do
        if [ -d "$subdir" ] ; then
            if [ "$subdir" != "." ]  && [ "$subdir" != ".." ]  ; then
                #_log_high "copy  '$subdir' to '${__in_dstFolder}/'  exclude : '${tmpFile}'"
                #cat ${tmpFile}"
                File__mirrorCopy "$subdir" "${__in_dstFolder}/" "${tmpFile}"
            fi
        fi
    done

    # Cleanup
    #if [ ! -z "$tmpFile" ] ; then rm "$tmpFile"  &>/dev/null ; fi
}

:<<'EOF'
Performs a mirror of a file/folder 
The operation is based on the rsync command, whose output on standard output is filtered.
This function is useful when it is itself used from another script.

@param [1] source file/folder
@param [2] destination file/folder
@param [3] optional file containing the list of files/folders to exclude (one name per line)
@return 0 only upon success
EOF

File__mirrorCopy() {
    local ret=-1

	local src="$1"
    local dstFolder="."
    local excludeFromFile=""
    if [ $# -ge 2 ] ; then
	    dstFolder="$2"
        if [ $# -eq 3 ] ; then
            excludeFromFile="$3"
        else
            if ! Args__checkCount ${FUNCNAME[0]} 2 "$#" "Usage: <source file/folder> [<destination file/folder> [file of files to exclude]] "; then return 1; fi
        fi
    else
        # When no 2nd arg specified destination is the basename filename of source in current working dir
        File__basename "$src" dstFolder
    fi

    if [ -d "$src" ] ; then
        if [ -f "$dstFolder"  ] ;  then
            _log_err "Source $1 is a dir but destination $2 is a file"
            return -2
        fi
        if [ ! -d "$dstFolder"  ] ;  then
            mkdir -p "$dstFolder"
        fi
    fi

    src_path=$(readlink -m "$src")
    dst_path=$(readlink -m "$dstFolder")
    if [ "${src_path}" = "${dst_path}" ] ; then
        _log_err "source and destination are the same"
        return -3
    fi
    # Use verbose but filter out useless printings:
    # - scanned folders (path ending with /) 
    # - line starting with 'sending incremental file list'
	if [ $? -eq 0 ] ; then
        if [ -z "$excludeFromFile" ] ; then
        	_log_dbg "  Copying $src to $dstFolder" 
            stdbuf -o0 rsync -avX "$src" "$dstFolder" | stdbuf -o0 grep -v '/$' | stdbuf -o0 grep -v '^sending incremental file list' | stdbuf -o0 grep -v '^[[:space:]]*total size' | stdbuf -o0 grep -v '^[[:space:]]*sent' | stdbuf -o0 grep -v '^[[:space:]]*$'
            #stdbuf -o0 rsync -avX "$src" "$dstFolder" | stdbuf -o0 grep -v '/$' | stdbuf -o0 grep -v '^sending incremental file list' | stdbuf -o0 grep -v ^[[:space:]]*"total size"  | stdbuf -o0 grep -v ^[[:space:]]*"sent" 
            #| awk -v CEOL=$(tput el) -v 'ORS=' '{ print "\r",CEOL,$0 }'
        else
        	_log_dbg "  Copying $src to $dstFolder excluding files from those listed in $excludeFromFile" 
	        stdbuf -o0 rsync -avX --exclude-from "$excludeFromFile" "$src" "$dstFolder" | stdbuf -o0 grep -v '/$' | stdbuf -o0 grep -v '^sending incremental file list' | stdbuf -o0 grep -v '^[[:space:]]*total size' | stdbuf -o0 grep -v '^[[:space:]]*sent' | stdbuf -o0 grep -v '^[[:space:]]*$'
            #| awk -v CEOL=$(tput el) -v 'ORS=' '{ print "\r",CEOL,$0 }'
        fi
	    # no need of -c option, it is purely local on disk
	fi
	ret=$?
	echo # print empty line
	return $ret
}

:<<EOF
Reads a YAML-like file consisting of a list of pairs 'property name : propery value'
on each like. This is not a YAML parser, it is just a basic reader 
for simple configuration without having to depend on other tools.
@param [1] path to the file to read the properties from
@param [2] reference to the output map where to store the properties,
           whereby keys are the prop names and values the prop values
           The map must be declare wit "declare A"
@returns 0 on success, 1 when not existing or not a regular file, 2 when invalid syntax. On error 2, the 
           prop map may already contain the values which could be read till that point.
EOF
File__readYAMLLikeFile() {
    local file="$1"
    local -n out_valueMap=$2

    if ! Args__checkCount ${FUNCNAME[0]} 2 "$#" "Usage: <file name> <ref output map>."; then return 1; fi

    if [ ! -f "$file" ] ; then
        _log_dbg "'$file' is not a valid regular file."
        return 1
    fi

    local line=""
    while IFS='' read -r line
    do
        # ignore empty lines
        Str__trim "$line" line
        if [ -z "$line" ] ; then
            continue
        fi
        if ! File__readYAMLLikeLine "$line" $2 ; then
         _log_err "Wrong configuration line '$line'. Ignoring."
        fi
    done < "$file"    

    if [ ! -z "$line" ] ; then
        Str__trim "$line" line
        # This can happen when last line does not end with 
        # new line
        if ! File__readYAMLLikeLine "$line" $2 ; then
            _log_err "Wrong configuration line '$line'. Ignoring."
        fi
    fi
    return 0
}    

File__readYAMLLikeLine()
{
    local line=$1
    local -n out_valueMap=$2
    local propPair=()
    local propName
    local propVal

    if Str__startsWith "$line" "#" ; then # this is a comment
        return 0
    fi

    if Str__startsWith "$line" "\"" ; then
#_log "line: '$line'"

        local left="${line%%\"*}" # This is empty.
        local right="${line#*\"}" # All string without first quote. with only one #, go to last separator in reverse order
#_log "left/right: '${left}' '${right}'"

        propName="${right%%\"*}" # This is the prop name without quotes
        local allWithoutQuotedKey="${right#*\"}" # This is all line without the quoted propname
#_log "propname/allWithoutQuotedKey: '${propName}' '${allWithoutQuotedKey}'"
        propVal="${allWithoutQuotedKey#*:}"
    else
        readarray -t -d':' propPair <<< "${line}"
        if [ ${#propPair[@]} -lt 2 ] ; then
            return 2
        fi
        propName="${propPair[0]}"
        propVal="${propPair[1]}"
        local cnt=2
        # in case the value contains itself the : separator, append all the remaining fields!
        while [ ${cnt} -lt ${#propPair[@]} ] ; do 
            local nextVal="${propPair[${cnt}]}"
            Str__trim "$nextVal" nextVal
            propVal="${propVal}:${nextVal}" ;
            cnt=$((${cnt} + 1))
        done
    fi

    Str__trim "$propName" propName
    Str__trim "$propVal" propVal
#_log "prop: '${propName}' '${propVal}'"
    if [ ! -z "${propName}" ] ; then
        out_valueMap[${propName}]="$propVal"
    fi
    return 0
}

declare -A __journal_job_progress
__done_steps_job_progress=0
__total_steps_job_progress=0
File__writeJobProgressFile() {
    
    File___writeJobProgressFile "${__SHELL_CURRENT_APP_JOB_ID__}" "$@"
}
File__setProgressFileTotalSteps() {
    __total_steps_job_progress=$1
}
File___writeJobProgressFile() {
    #sleep 0.5 # TMP FOR DEBUG

    __done_steps_job_progress=$(( ${__done_steps_job_progress} + 1))
    local doneSteps=${__done_steps_job_progress}
    local nbSteps=${__total_steps_job_progress}    
    local jobid="$1"
    shift
    local msg="$1"
    shift
    local customData=""
    if [ $# -gt 0 ] ; then
        customData=",
$1"
    fi
    local appName="${__SHELL_CURRENT_APPNAME__}"
    local progresPerc=0

    # Update the internal journal and setup the JSON journal
    local journal
    local jiter
    local utc
    read utc< <(date +'%s')
    # NOTE: there may a progress reported for the same UTC time since it is in seconds
    # Adding the count (commented line) does not work insofar the dictionary sort won't sort
    # once the counter is > 10
    #__journal_job_progress["${utc}"]="$msg"
#    __journal_job_progress["${#__journal_job_progress[@]}-${utc}"]="$msg"
__journal_job_progress["${utc}-${#__journal_job_progress[@]}"]="$msg"

    for jdate in "${!__journal_job_progress[@]}" ; do
        local jentry="${__journal_job_progress[$jdate]}"
        journal="\"${jdate}\" : \"${jentry}\",
${journal}"
    done
    Str__trimEnd "$journal" journal
    Str__trimEnd "$journal" journal ","

    if [ $nbSteps -ne 0 ] ; then
        Float__calc "(100 * ${doneSteps}) / ${nbSteps}" progresPerc
    fi

    if [ "$jobid" = "~" ] ; then
        Sys__getPID jobid
    fi

    local mylogDir
    _getLogDir mylogDir
    local filename="${mylogDir}/${appName}.job.${jobid}"

    #_log_vars filename jobid doneSteps nbSteps progresPerc msg 

   (
    flock -w 5 10 || return 1

#stdbuf -o0 
cat<<EOF > "$filename"
{
    "job-id" : "${jobid}",
    "total-steps" : "${nbSteps}",
    "completed-steps" : "${doneSteps}",
    "progress-percentage" : "${progresPerc}",
    "last-message" : "${msg}",
    "journal" : { ${journal} }${customData}
}
EOF
    ) 10>/var/lock/${appName}_${jobid}

}

# --------------------------------------------------------------------------------------
# Date API
# --------------------------------------------------------------------------------------
:<<'EOF'
Given a string of the form yy-mm-dd hh:mm:ss, extract the year, month and day items
and stores it into the passed var refs.
@param[1] Input date time string of the form "yy-mm-dd hh:mm:ss"
@param[2] extracted output year
@param[3] extracted output month
@param[4] extracted output day
EOF
Date__readYMD()
{
	local __in_yymmdd=$1
	local -n __out_y=$2
	local -n __out_m=$3
	local -n __out_d=$4
	local dateTime=()
	local dateYMD=()
	readarray -t -d' ' dateTime <<< "${__in_yymmdd}" # split date and time
	readarray -t -d'-' dateYMD <<< "${dateTime[0]}" # split date into y,m,d
	__out_y="${dateYMD[0]}"
	__out_m="${dateYMD[1]}"
    local __internal_readYMD_data
	Str__trimEnd "${dateYMD[2]}" __internal_readYMD_data
	__out_d="${__internal_readYMD_data}"

	Str__trimEnd "${dateYMD[1]}" __internal_readYMD_data
	__out_m="${__internal_readYMD_data}"

	Str__trimEnd "${dateYMD[0]}" __internal_readYMD_data
	__out_y="${__internal_readYMD_data}"


    #_log "=====> Date__readYMD $1 => ${__out_y} ${__out_m} ${__out_d}"
}

# Fully optimized version
Date__readYMD2()
{
	local __in_yymmdd=$1
	local -n __out_y=$2
	local -n __out_m=$3
	local -n __out_d=$4
:<<'EOF'
	local dateYMD="${__in_yymmdd%% *}"
	local dateTime="${__in_yymmdd#* }"
    local monthday
    __out_y="${dateYMD%%-*}"
    monthday="${dateYMD#*-}"
    __out_m="${monthday%%-*}"
    __out_d="${monthday#*-}"
EOF
    local dateYMD
    local dateTime
    local monthday
    Str__split "${__in_yymmdd}" dateYMD " " dateTime 1
    Str__split "${dateYMD}" __out_y "-" monthday 1
    Str__split "${monthday}" __out_m "-" __out_d 1
    _log "=====> Date__readYMD $1 => ${__out_y} ${__out_m} ${__out_d}"
}

:<<'EOF'
Given a date string of the form yy-mm-dd hh:mm:ss, tells this date is earlier than 
the supplied YMD date components.
@param[1] Input date time string of the form "yy-mm-dd hh:mm:ss"
@param[2] extracted output year
@param[3] extracted output month
@param[4] extracted output day
@return 0 if less, 1 otherwise
EOF
Date__isLessOrEqualThan()
{
    local y1
    local m1
    local d1
    Date__readYMD "$1" y1 m1 d1
    local y2="$2"
    local m2="$3"
    local d2="$4"
    
    if [ $y1 -le $y2 ] ; then 
        if [ $m1 -le $m2 ] ; then 
            if [ $d1 -le $d2 ] ; then 
                return 0
            else
                return 1
            fi
        else
            return 1
        fi
    else
        return 1
    fi
}

Date__timestamp()
{
    local -n __out_timestamp=$1
    local __in_utcSecs
    read -r __in_utcSecs < <(date +'%s')
    __out_timestamp=${__in_utcSecs}
}

declare -A Date__TIMER_TABLE
Date__TIMER_TABLE_INDEX=0
Date__startTimer()
{
    local -n __out_timer_id=$1
    # Read utc time
    local __utcSecs
    Date__timestamp __utcSecs
    # Set timer id
    Date__TIMER_TABLE_INDEX=$((${Date__TIMER_TABLE_INDEX} + 1))
    Date__TIMER_TABLE[${Date__TIMER_TABLE_INDEX}]=${__utcSecs}
    __out_timer_id=${Date__TIMER_TABLE_INDEX}
}

Date__elapsedSecondsTimer()
{
    local __in_timer_id=$1
    local -n __out_secsElapsed=$2
    local __endTimestamp
    Date__timestamp __endTimestamp
    local __startTimestamp="${Date__TIMER_TABLE[${__in_timer_id}]}"
    if [ ! -z "${__startTimestamp}" ] ; then
        __out_secsElapsed=$(( ${__endTimestamp} - ${__startTimestamp}  ))

        if [ $# -gt 2 ] ; then
            echo "${__out_secsElapsed}"
        fi
        return 0
    else
        return 1
    fi
}

Date__elapsedMinutesTimer()
{
    local __in_timer_id=$1
    local -n __out_minElapsed=$2
    local _secsElapsed=$2
    if Date__elapsedSecondsTimer $1 _secsElapsed ; then
        Float__calc "${_secsElapsed} / 60" ${!__out_minElapsed}
        if Str__startsWith "${__out_minElapsed}" "." ; then
            __out_minElapsed="0${__out_minElapsed}"
        fi
    else
        return 1
    fi
}


# --------------------------------------------------------------------------------------
# Terminal API
# --------------------------------------------------------------------------------------
declare -A Term__Palette 
Term__useListLinesColors=1
Term__listLinesColorCounter=0
Term__listLinesColors=()
Term__listLinesCounter=0
Term__resetColors="$(tput sgr 0)"
Term__eraseLine="$(tput el)"
for __Term__i in $(Int__series 127)
do
    Term__Palette[$((${__Term__i}-1))]=$((${__Term__i}-1))
done


:<<'EOF'
Implements a simple countdown
@param1: number of seconds till timeout
EOF

Term__countdown() {
    if ! Args__checkCount ${FUNCNAME[0]} 3 "$#" "Usage: <text> <number of seconds> <text>"; then return 1; fi

    local secsAsString="$2"
    local secsLen=${#secsAsString}
    local prefix="$1"
    local secs=$2
    local suffix="$3"
    local pid
    while [ $secs -gt 0 ]; do
        sleep 1 &
        pid=$!
        printf "\r%s%${secsLen}d%s" "$prefix" $secs "$suffix"
        secs=$(($secs - 1))
        wait $pid
    done
    echo
}

:<<'EOF'
Resizes the terminal the number of lines and columns as specified in the arguments.
Basically, this is a wrapper for the 'resize' commmand, which standard output is masked.

@param [1] number of lines
@param [2] number of columns
@returns the return value of the bash 'resize' command
EOF

Term__resize()
{
    local nbRequestedRows="$1"
    local nbRequestedCols="$2"

    resize -s $nbRequestedRows $nbRequestedCols &> /dev/null
}

Term__rows()
{
    local -n nbRows=$1
    local currentSize=($(stty size))
    nbRows=${currentSize[0]}
}

Term__cols()
{
    local -n nbRows=$1
    local currentSize=($(stty size))
    nbRows=${currentSize[1]}
}

:<<'EOF'
Ensures that the terminal has at a minimum the size as specified in the arguments.
If the current terminal is large enough, its size is not modified.

@param [1] number of minimum rows
@param [2] number of minimum columns
@returns the return value of the bash 'resize' command
EOF

Term__resizeMinimum()
{
    local nbRequestedRows="$1"
    local nbRequestedCols="$2"
    local currentSize=($(stty size))
    local newNbRows=${currentSize[0]}
    local newNbCols=${currentSize[1]}
    if [ ${currentSize[0]} -lt $nbRequestedRows ] ; then
        newNbRows=$nbRequestedRows    
    fi
    if [ ${currentSize[1]} -lt $nbRequestedCols ] ; then
        newNbCols=$nbRequestedCols    
    fi
    resize -s $newNbRows $newNbCols &> /dev/null
}

:<<'EOF'
Prints a string on standard output by overwriting last printed line. 
A carriage return is done and line till the end is cleared prior to printing value
@param [1] string print on the standard output
EOF

Term__updateLine() {
    awk -v "value=$1" -v "CEOL=${Term__eraseLine} " -v 'ORS='  '{ print "\r",CEOL,value }' <<EOF

EOF
}

:<<'EOF'
This enables to show and update a text-based progress bar on the terminal. 
The bar is of the form, e.g. : |=====                | 25%
The bar is displayed the first time that the function is called according to a
maximum step value and a number of incrementation achieved steps.

The masking of the cursor is activated when this function is called. It is up to the calling
script to restore the terminal settings (e.g. by using Term__reset) when the progress bar is not used
anymore.

@param [1] unique identifying name of the bar. This will be used to define global env. var.
           used for the purpose of managing the bar.
@param [2] max steps
@param [3] number of achieved steps at the call of this function. This is an incremental value.
           E.g. assuming a max step of 100, calling 4 times this function with 25 achieved steps
           results in a 100% completion.
@returns 0 when 100% is reached, 1 otherwise.
EOF

Term__updateProgressBar() {
    Term__maskCursor

    local progressBarName="$1"
    local pbMaxSteps="$2"
    local pbNewStepsDone="$3"
    local pbDisplayLineSize=50
    local pbDisplayProgressLineSize=0
    local pbProgressStatusVarName="__SHELL_API_TERM_PROGRESS_BAR_${progressBarName}__"
    local pbDisplayProgressLineIncVarName="__SHELL_API_TERM_PROGRESS_BAR_${progressBarName}_inc__"
    if [ ! -v "$pbProgressStatusVarName" ] ; then
        eval "$pbProgressStatusVarName=0"
        eval "Float__calc \"$pbDisplayLineSize / $pbMaxSteps\" $pbDisplayProgressLineIncVarName"
# echo "INIT ${!pbDisplayProgressLineIncVarName}_${pbDisplayLineSize}_${pbMaxSteps}"
    fi
    if [ ${!pbProgressStatusVarName} -le "$pbMaxSteps" ] ; then
        eval "$pbProgressStatusVarName=$(( ${!pbProgressStatusVarName} + $pbNewStepsDone ))"
        if [ ${!pbProgressStatusVarName} -gt "$pbMaxSteps" ] ; then 
            eval "$pbProgressStatusVarName=$pbMaxSteps"
        fi
        eval "pbDisplayProgressLineSize=$(Int__calc "${!pbDisplayProgressLineIncVarName} * ${!pbProgressStatusVarName}")"
#  echo "NEW ${!pbProgressStatusVarName}_${!pbDisplayProgressLineIncVarName}_$pbDisplayProgressLineSize"
    else
        Term__reset
        return 0
    fi
    local displayLineSizeRemaining=$(($pbDisplayLineSize - $pbDisplayProgressLineSize))
    local i=0
    printf "\r|"
    while [ $i -le $pbDisplayProgressLineSize ] ; do printf "=" ; i=$(($i+1)); done
    printf "%${displayLineSizeRemaining}s"
    printf "| "
    Int__calc "(${!pbProgressStatusVarName} * 100.0) / $pbMaxSteps"
    echo -n "%"
    return 1
#    sleep 1
}


Term__clear()
{
    clear -x
#    tput cup 0 0 
#    tput ed
}

:<<'EOF'
Make the cursor invisible and disable echoing.
EOF

Term__maskCursor()
{
    tput civis 2>/dev/null # invisible cursor
    stty -echo 2>/dev/null # no echo
}

:<<'EOF'
Reverse operation of cursor masking, it ensures the cursor is visible
and key echoing is enabled.
EOF

Term__restoreCursor()
{
    tput cnorm 2>/dev/null
    stty echo 2>/dev/null
}

Term__eatReturns()
{
    #while read -r -t 0; do read -r; done
    read -d '' -t 0.1 -n 10000    
}

:<<'EOF'
Enter the private buffer mode, whereby the existing scrollback can be saved
and restored afterwards when either Term__exitPrivateBufferMode or Term__reset is called.
EOF

Term__enterPrivateBufferMode()
{
    tput sc     
    printf \\33\[\?1047h    
}

:<<'EOF'
Exits the private buffer mode.
EOF

Term__exitPrivateBufferMode()
{
    printf \\33\[\?1047l 
    tput rc
}

:<<'EOF'
Resets the terminal by enforcing cursor visibility and echoing and exiting
of private buffer mode.
EOF

Term__reset()
{
    Term__restoreCursor    
}

:<<'EOF'
Moves the cursor to the left for the amount of specified chars
@param[1] number of char pos
EOF

Term__cursorMoveLeft() {
    if ! Args__checkCount ${FUNCNAME[0]} 1 "$#" "Usage: <number of moves>"; then return 1; fi

    local nbChars=$1
    local i=0
    if [ $nbChars -gt 0 ] ; then
        while [ $i -lt $nbChars ] ;
        do    
            printf '\033[D'    
            i=$(($i + 1))
        done        
    fi
}

Term__moveCursorUp() {
    if ! Args__checkCount ${FUNCNAME[0]} 1 "$#" "Usage: <number of lines to move up>"; then return 1; fi
    local nbLines=$1
    local i=0
    if ! Int__isInt "$1" ; then
        return 1
    fi

    while [ $i -lt $nbLines ] 
    do
        printf '\033[A'
        i=$(($i + 1))
    done
    return 0
}

Term__eraseLinesUp() {
    if ! Args__checkCount ${FUNCNAME[0]} 2 "$#" "Usage: <number of lines to erase> <0:preserve cursor pos|1:move cursor while erasing>"; then return 1; fi
    local nbLines=$1
    local preserveCursorPosition=$2
    local i=0

    if ! Int__isInt "$1" ; then
        return 1
    fi

    while [ $i -lt $nbLines ] 
    do
        Term__eraseCurrentLine
        printf '\033[A'
        i=$(($i + 1))
    done
    if [ $preserveCursorPosition -eq 0 ]; then
        # Rewind up
        i=0
        while [ $i -lt $nbLines ] ;
        do
            printf '\033[B'
            i=$(($i + 1))
        done 
    fi
    return 0
}


:<<'EOF'
Erase the amount of terminal lines as specified by first argument
starting from the current line.
The cursor pos is reset to the line start of the current line before call
of this function.
@param[1] number of lines to erase
@param[2] optional : 'true' for rewinding, 'false' for not rewinding
EOF

Term__eraseLines() {
    if ! Args__checkMinCount ${FUNCNAME[0]} 1 "$#" "Usage: <number of lines to erase>"; then return 1; fi

    local nbLines=$1
    local i=0
    if ! Int__isInt "$1" ; then
        return 1
    fi

    while [ $i -lt $nbLines ] ;
    do
        Term__eraseCurrentLine
        printf '\033[B'
        i=$(($i + 1))
    done

    if [ $# -eq 2 ] ; then 
        if ! $2 ; then 
            return 0
        fi
    fi

    # Rewind up
    i=0
    while [ $i -lt $nbLines ] ;
    do
        printf '\033[A'
        i=$(($i + 1))
    done    
    return 0
}

:<<'EOF'
Erase the current terminal line and pushes back the cursor
to the line start.
EOF

Term__eraseCurrentLine() {
    printf "\033[0m\r${Term__eraseLine}"
}



:<<'EOF'
Erase the current terminal line and pushes back the cursor
to the line start.
EOF

Term__eraseCurrentAndJumpCursorToNextLine() {
    printf "\033[0m\r${Term__eraseLine}"
    printf '\033[B'
}

:<<'EOF'
Prints banner frame which fits with the content of the message. 

There are various parameters to control aspect of the frame.

Special lines are interpreted:

* <hr> prints a separation line

@param [1] message to display
@param [2] char for the horizontal frame borders
@param [3] char for the left frame border
@param [4] char for the right frame border
@param [5] separator char for fields
@param [6] number of blank lines at top and bottom of the frame
@param [7] top and bottom h border visibility : 1=no top, 2=no bottom, 3=none
@example:


With text="
<hr>

Backup of AppData (Application Data) of distant Windows system

Please check system is running and reachable over network !
"

Term__printBanner "\$text" "|" " " "-" 1

results in:
 ________________________________________________________________
|                                                                 
| disk                                                            
|---------------------------------------------------------------- 
|                                                                 
| Backup of AppData (Application Data) of distant Windows system  
|                                                                 
| Please check system is running and reachable over network !     
|________________________________________________________________ 
EOF

Term__printBanner() {
        local msg="$1"
        local hBorder=$2
        local vLeftBorder=$3
        local vRightBorder=$4
        local vSepChar=$5
        local nbLineBorderGap=$6
        # Frame flag: 0 display all, 1 hide top frame, 2 hide bottom frame
        local frameFlag=$7
        local nbCharsLongestLine=0
        local line
        while IFS=''  read -r line
        do
                local nbChars=$(Str__len "$line") 
                if [ $nbChars -gt $nbCharsLongestLine ] ; then      
                 nbCharsLongestLine=$nbChars; 
                fi
        done <<< "$msg"

        nbCharsBannerWidth=$(( $nbCharsLongestLine + 3 ))
        local blankLine="${vLeftBorder}$(Str__spaces $nbCharsBannerWidth)${vRightBorder}\n"
        local separationLine="${vLeftBorder}$(Str__seq "$vSepChar" $nbCharsBannerWidth)${vRightBorder}\n"

        if [ $(( $frameFlag & 1 )) -eq 0 ] ; then 
            printf " $(Str__seq "$hBorder" $nbCharsBannerWidth)\n"
        fi

        local cnt=($(Int__series $nbLineBorderGap))
        local c=0
        for c in "${cnt[@]}" ; do printf "${blankLine}" ; done

        # Display the text itself
        while IFS='' read -r line
        do
                local nbChars=$(Str__len "$line") 
                local nbPaddingChars=$(( $nbCharsLongestLine - $nbChars +1 ))
                 # debug echo "nbChars=$nbChars nbCharsLongestLine=$nbCharsLongestLine padding=$nbPaddingChars"
                if [ "$line" == "<hr>" ] ; then
                         printf "${separationLine}" 
                else
                        Str__trim "$line" line
                        printf "${vLeftBorder} $line"
                        printf "$(Str__spaces $nbPaddingChars) ${vRightBorder}\n"
                fi
        done <<< "$msg"

        for c in "${cnt[@]:0:$nbLineBorderGap-1}" ; do printf "${blankLine}" ; done
    
        if [ $(( $frameFlag & 2 )) -eq 0 ] ; then 
            printf "${vLeftBorder}$(Str__seq "$hBorder" $nbCharsBannerWidth)${vRightBorder}"
            printf "\n"
        fi
}

:<<'EOF'
Provided a table which rows are given as lines and cells are given as space-separated values in each rows,
this function computes the maximum number of chars that occupies each column.
To operation, this function relies on function Term__printTableRow, whereby the second and third parameters 
are used specifically for that purpose.

@param [1] the number of columns of the table
@param [2] the table itself
@return an array giving the maximum number of chars occupied by each column. E.g "10 6 20" for a 3-column 
table
@example here an example of parameters:
/dev/sda 447,1G disk
/dev/sda1 100M part vfat
/dev/sda2 16M  part 
EOF

Term__resolveMaxColumnsWidth() {
        local nbCols=$1
        local list="$2"
        local i=0
        local maxColsWidths=()
        local maxColsWidthsAsString
        local iterSeq=$(seq 0 $(( $nbCols-1 )))
        for i in $iterSeq ; do maxColsWidths+=(0); done
        while IFS='' read -r line
        do 
                maxColsWidthsAsString="${maxColsWidths[@]}"
                computedMaxRowColsWidth=($(Term__printTableRow "$line" "" "$maxColsWidthsAsString" ))
                for i in $iterSeq 
                do
                        maxColsWidths[$i]=${computedMaxRowColsWidth[$i]}
                done        
        done <<< "$list"
        echo "${maxColsWidths[@]}"
}

:<<'EOF'
This function is called internally by Term__printTableRow. See related documentation.
EOF

Term___printTableRow() {
        local msg=()
        local colCharMaxWidths=($2)
        local vLeftBorder=$3
        local vRightBorder=$4
        local vCellSepChar=$5
        local extraPadding=$6
        local field=""
        local first=0
        local cnt=0

        if [ -z "$extraPadding" ] ; then
            extraPadding=0
        fi

        # Handle the specific case where the first field would be empty
        msg=($1)

        #echo "field ${msg[0]}" >&2
        #if Str__startsWith "${msg[0]}" '033[1m' ; then 
        #    echo "FOUND ! ${msg[0]}" >&2
        #    msg[0]=$(Str__trimStart "${msg[0]}" '\033[1m')
        #fi

        # This is relevant when this function is used to compute max size of each column
        # We create an array holding the max value for each column
        #local i=0
        local maxColsWidths=()
        local resolveMaxColsWidth=0        
        if [ ${#colCharMaxWidths[@]} == 0 ] ; then
                resolveMaxColsWidth=0
        else
                resolveMaxColsWidth=1
        fi

        if [ $resolveMaxColsWidth -eq 0 ] ; then
                maxColsWidths=($3)
        else
                printf "${vLeftBorder} "
        fi

        # Handle specific line command, here 
        # escaping a full line to be excluded of the printing
        # as a table cell
#        if [ $resolveMaxColsWidth -ne 0 ] ; then
#                echo "${maxColsWidths[@]}"
#        else
        local lineEscapeMagic='\\\\'
        local escapedLine="${1#*$lineEscapeMagic}" 
#echo "ESCAPED? '${1#*$lineEscapeMagic}'" >&2
            if [ ! -z "$escapedLine" ] && [ "$escapedLine" != "$1" ] ; then
                if [ $resolveMaxColsWidth -eq 0 ] ; then
                    echo "${maxColsWidths[@]}"
                    return 0
                else
                    #echo "ESCAPED LINE '$1' is $escapedLine" >&2
                    Term__listLinesCounter=$(( $Term__listLinesCounter + 1 ))
                    tput sitm
                    escapedLine="${escapedLine//§/ }"
                    echo -n "$escapedLine"
                    #tput cnorm
                    return 0
                fi
        fi
#        fi

        # Color settings
        if [ $resolveMaxColsWidth -ne 0 ] ; then
            if [ ${Term__useListLinesColors} -eq 0 ] ; then
                local colIndex=${Term__listLinesCounter}
                local termColor="${Term__listLinesColors[${Term__listLinesCounter}]}"
                if [ ! -z "$termColor" ] ; then
                    printf "$termColor"
                fi
            fi
        fi
#echo "'printing line'" >&2
        for field in "${msg[@]}" 
        do
            #local printField="$field" # ${field/§§/}
            #Str__toTail field ";" verylast  
        #field=${field#*§§}
                local nbChars=${#field} 
# echo "f='$field' cnt=$cnt nbChar=$nbChars max='${maxColsWidths[@]}' ${#maxColsWidths[@]}" >&2
                if [ $resolveMaxColsWidth -eq 0 ] ; then
                        if [ $nbChars -gt ${maxColsWidths[$cnt]} ] ; then
                                maxColsWidths[$cnt]=$(( $nbChars + 1 )) # we always keep one additional char as end space separator
                        fi
                else
                        if [ $first -eq 0 ] ; then
                                first=1
                        else
                                printf "${vCellSepChar} "
                        fi
                        local nbPaddingChars=$(( ${colCharMaxWidths[$cnt]} - $nbChars + $extraPadding ))                        
#echo "printing '$field'  field with padding $nbPaddingChars, maxcol=${colCharMaxWidths[$cnt]}, nbChars=$nbChars  extraPadding=$extraPadding" >&2
                        field="${field//§/ }"
                        #echo "'$field'" >&2
                        if Str__startsWith "$field" '\\U' ; then
                        #echo YES >&2
                            unicode_char="$field"
                            printf ${unicode_char}
                            case "$field" in
                            '\U1F511'|'\U1F4F6') nbPaddingChars=0;;
                            *) nbPaddingChars=1;;
                            esac
                            #if [ $nbChars -ge 4 ] ; then nbPaddingChars=0 ; fi
                        #elif [ "$field" == "-" ] ; then
                        #    printf " "
                        else
                            printf "%s" "$field"
                        fi
                        Str__spaces "$nbPaddingChars"
                fi
                cnt=$(( cnt + 1 ))
        done

        if [ $resolveMaxColsWidth -eq 0 ] ; then
                echo "${maxColsWidths[@]}"
                return 0
        else
                if [ $cnt -lt ${#colCharMaxWidths[@]} ] ; then
                        printf "${vCellSepChar} $(Str__spaces $(( ${colCharMaxWidths[$cnt]}  + $extraPadding )))"
                fi
                printf "${vRightBorder}"
        fi
#printf "E" 

        Term__listLinesCounter=$(( $Term__listLinesCounter + 1 ))
}

:<<'EOF'
Provided a table which rows are given as lines and cells are given as space-separated values in each rows,
this function displays the table with fixed size columns given by second parameter
as a list of char length for each column. By using Term__resolveMaxColumnsWidth prior to this function,
one can compute the exact width of each column to match the largest string value which can be found 
in that column.

The actual function which is achieving the display is Term___printTableRow (with 3 underscores).
This wrapper function is in charge of setting the line formatting (e.g. color) according to the line header
which is ended by '§§'.

@param [1] the table itself
@param [2] list of char length for each column. E.g. "10 6 8" for a 3-column table.
@param [3] char used for the left vertical border
@param [4] char used for the right vertical border
@param [5] char used as cell separator
@param [6] optional, a number of extra end-padding for the cells

@example here an example of table:
table:
/dev/sda 447,1G disk
/dev/sda1 100M part vfat
/dev/sda2 16M  part 
EOF

Term__printTableRow()
{
    if [ -z "$2" ] ; then
        Term___printTableRow "$1" "$2" "$3" "$4" "$5" "$6" 
    else
        local lineFormatting="${1%%§§*}" 
        if [[ ${lineFormatting} =~ ^\[([^\]]+)\](.*) ]] ; then
                local __metrics="${BASH_REMATCH[1]}"
                lineFormatting=${lineFormatting//\[${__metrics}\]/}
        fi
        local rawLine=${1#*§§}
        if [ "$lineFormatting" != "$1" ] ; then
            printf "$lineFormatting"
        fi
        Term___printTableRow "$rawLine" "$2" "$3" "$4" "$5" "$6" 
    fi
}

# --------------------------------------------------------------------------------------
# Test framework API
# --------------------------------------------------------------------------------------

Test__TC=0

:<<'EOF'
Executes a test

@param [1] test description
@param [2] expected result, i.e. 0 (success) or 1 (fail)
@param [3] command line to execute
@return 0 on success, 1 otherwise
EOF

_test() {
        local testDesc="$1"
        local expectedRes=$2
        local cmpStr="$3"
        shift
        shift
        local cmd="$@"
        local stdout=""

        if [ ${__SHELL_TEST_GEN_EXAMPLES__} -eq 0 ] ; then
            _log "# $testDesc:"
            #for i in $@
            #do
             #   echo #printf "%s " "$i"
            #done
            local tcmd
            Str__trim "$cmd" tcmd
            _log "$tcmd"
            _log ""
        else
            _log "" 
            _log "--- --- --- Executing test '$testDesc' : $cmd"
            _log ""
            stdout=$(eval "$cmd")
            #_log "$stdout"
            if ([ $? -ne 0 ] && [ $expectedRes -eq 0 ]) || ([ $? -eq 0 ] && [ $expectedRes -ne 0 ]) ; then
                    _log_err "TEST FAILED: '$cmd'"
                    _log_err "  Please check above error output"
                    _log_err "  Cleanup if necessary"
                    _exit -5 ""
                    return 1
            else
                    if [ $? -ne 0 ] && [ $expectedRes -ne 0 ] ; then
                            _log_err "TEST SUCCESS: COMMAND FAILED BUT THIS WAS THE EXPECTED BEHAVIOR: '$cmd'"
                    fi

                    if [ ! -z "$cmpStr" ] ; then
                            if [ "$stdout" != "$cmdStr" ] ; then
                                    echo "FAILED : stdout mismatch '$stdout' != '$cmdStr' (expected)"
                            fi #else so far ok
                    fi #else so far ok
            fi
            _log "$stdout"
            _log "" 
            _log "--- --- --- test was SUCCESSFUL $cmd"
            return 0
        fi
}

:<<'EOF'
Executes the case which ID is specified as argument.
When batch execution all tests, the ID will be an increasing
number starting from 0.
But a random ID can be passed for executing a specific test
run via _test. It is up to the _testCase user implementation to 
handle that ID (which can be a random string). Typically, 
there would be a case enumeration where the numeric ID and the 
alternative clear text ID is defined like 0|<my test name>)
@return 0 on success, 1 otherwise
EOF

_testCase()
{
    if [ $# -ne 1 ] ; then
    	_log_err "${FUNCNAME[0]}: invalid use. 1 arg expected, $# passed ($*)"        
        return 1        
    fi

    local testCase="$1"
    if [ ${__SHELL_TEST_GEN_EXAMPLES__} -ne 0 ] ; then
        _log "" 
        _log "--- --- Executing test case '$testCase'"
        _log ""
    fi
    _invokeCallback testCase "$testCase"
}

:<<'EOF'
Executes all tests by invoking testCase passing 
as argument an increment ID starting from 0
@return 0 on success, 1 otherwise
EOF

_testAll()
{
        Test__TC=0
        if [ ${__SHELL_TEST_GEN_EXAMPLES__} -ne 0 ] ; then
            _log "---------------------------------------------------------------------------------"
            _log "--- Running all test cases"
            _log "--- "
        fi
        local res=1
        
        _testCase ${Test__TC}
        res=$?
        while [ $res -eq 0 ] 
        do
                Test__TC=$(( ${Test__TC} + 1 ))
                _testCase ${Test__TC}
                res=$?
        done
        if [ ${__SHELL_TEST_GEN_EXAMPLES__} -ne 0 ] ; then
            _log "---------------------------------------------------------------------------------"
            _log ""
            _log "${Test__TC} test cases were run successfully"
            if [ $res -eq 100 ] ; then
                _log "All test cases are deemed to have run successful (Last return code=100)"
            fi
            _log ""
        fi        
        return 0
}

:<<'EOF'
Examples of usage:

test__perf 5000  'var=$(dirname ${BASH_SOURCE[0]})'
#test__perf 5000  'var=${BASH_SOURCE[0]%/*}'

#test__perf 5000  'GENAPP__VARS["MYDIR"]="$(readlink -f "${Genapp__sourcedirname}")"'
test__perf 5000  'read Genapp__sourcedirname< <(readlink -f "${Genapp__sourcedirname}")'

EOF
test__perf()
{
    local __nbIter=$1
    local iterSeq=$(seq 0 $__nbIter)
    shift

    time for __iterStep in $iterSeq; do eval "$@" ; done
}
_initShellApi
