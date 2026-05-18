#!/bin/bash
###############################################################################
#
# Genapp tool
#
# Copyright (c) 2026 Michel Mehl. All rights reserved.
#
# ------------------------------------------------------------------------------
#
# This file implements the Genapp tool to generate shell script app skeletons
# using the shell-api library. 
#
# It includes a sub-skeleton file for managing options, as well as one including
# help functions to enable packaging with dpkg.
#
# ------------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
###############################################################################

# GENAPP__VARS is aimed at storing variables specific to this app
# to avoid conflicts with other vars should this file be included elsewhere
declare -A GENAPP__VARS

Genapp__sourcedirname="${BASH_SOURCE[0]%/*}" # "$(dirname ${BASH_SOURCE[0]})"
GENAPP__VARS["MYDIR"]="$(readlink -f "${Genapp__sourcedirname}")"
GENAPP__VARS["SHELLAPI_DIR"]="%SHELL_API_DIR%"

if [[ ! -v __SHELL_API_CORE_LOADED__ ]]; then
    source "${GENAPP__VARS["MYDIR"]}/${GENAPP__VARS["SHELLAPI_DIR"]}/shell-api-core.sh" "Genapp"
fi

:<<'EOF'
# If necessary include of these modules
eval $_loadm<<<'shell-api-sys'          # process control functions
eval $_loadm<<<'shell-api-dev'          # device access functions
eval $_loadm<<<'shell-api-packing'      # package management functions (loading)
eval $_loadm<<<'shell-api-net'          # network related functions
EOF

eval $_loadm<<<'shell-api-yaml'         # YAML read/write functions, mandatory core has a dependency on it

source "${GENAPP__VARS["MYDIR"]}/genapp__vars.sh" 
source "${GENAPP__VARS["MYDIR"]}/genapp__options.sh" 
source "${GENAPP__VARS["MYDIR"]}/genapp__help.sh" 

:<<'EOF'
Framework callback for getting the default configuration file path if none is defined
in user space below .config/<appname>.
@param [1] A reference to the variable where the path shall be stored
EOF

Genapp__getDefaultConfigFile()
{
        local -n out_ConfileFilePath=$1
        out_ConfileFilePath="${GENAPP__VARS["MYDIR"]}/genapp.yml"
        return 0
}


Genapp__parseArgsHandleOptionLessArg() {
        local rank=$1
        shift
        local value="$@"
:<<'EOF'
        # Handle here optionless arguments which are not provided with - or -- 
        # 'rank' givens the rank of the arguments as it is read from left to right 
        # on command line
        case ${rank} in
                0) 
                    GENAPP__VARS["dummy_option1_value"]="${value}" ;                 
                    return 0 
                    ;; 
                1) 
                    GENAPP__VARS["dummy_option2_value"]="${value}" ; 
                    return 0  
                    ;;
                *) return 1 
                ;;
        esac        
EOF
        return 1 
}

Genapp__parseArgs() {
    local argc=0
    local arg_cnt=0

    _log_dbg "Genapp__parseArgs"

    _parseFromArgToVars GENAPP__OPTION_LIST_DESC GENAPP__OPTION_LIST_ARGS GENAPP__OPTION_LIST_ACTI GENAPP__OPTION_LIST_VALS argc arg_cnt "$@"

:<<'EOF'
    # Handle here specific cases e.g. 
    # - raise an error when no arguments at all is supplied
    # - or set up a specific handling with defaults params
    if [ $argc -eq 0 ] ; then
        _susage "missing arguments"
    fi
EOF
    _log_dbg "Genapp__parseArgs argc='$argc' arg_cnt='$arg_cnt'"
}

:<<'EOF'
Callback called for cleaning up app upon signal arising

@param [1] the code with which the app will exit, i.e. the initially caught exit code

EOF

Genapp__cleanup()
{
:<<EOF
    local appName="${__SHELL_CURRENT_APPNAME__}"
    _log "${appName} cleaning up"
EOF
}

Genapp__main() {
    local allargs=("$@")

    if ! _parseArgs "${allargs[@]}" ; then
            _exit -1 "Failed to parse arguments"
    fi

}

Genapp__test() {
    :
}

allArgs=("$@")
if _main "${allArgs[@]}" ; then

        if ${GENAPP__VARS["verbose"]} ; then
            _quit "${__SHELL_CURRENT_APPNAME__} has finished."
        else
            _quit ""
        fi

else
        _exit -1 "${__SHELL_CURRENT_APPNAME__} ended with a failure. Please check above messages."
fi



