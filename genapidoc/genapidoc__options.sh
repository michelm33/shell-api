#!/bin/bash
###############################################################################
#
# Genapidoc
#
# Copyright (c) 2026 Michel MEHL. All rights reserved.
#
# ------------------------------------------------------------------------------
#
# This file contains the definition of all options supported by Genapidoc.
#
# ------------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
###############################################################################

# Keys are option alternatives separated by |
declare -A GENAPIDOC__OPTION_LIST_SDESC # Option short description 
declare -A GENAPIDOC__OPTION_LIST_DESC # Option description
declare -A GENAPIDOC__OPTION_LIST_ARGS # Tells whether arg expected or none
declare -A GENAPIDOC__OPTION_LIST_ARGS_TYPE # Give the type of the argument(s)
declare -A GENAPIDOC__OPTION_LIST_VALS # Executed code when processing an expected arg
declare -A GENAPIDOC__OPTION_LIST_ACTI # Executed code when option is detected
declare -A GENAPIDOC__OPTION_LIST_INTERN # Tells whether the option is not intended for end-users or only for advanced ones

:<<'EOF'
-h, -v, --man are standard options
EOF

GENAPIDOC__OPTION_LIST_SDESC["--help|-h"]="Displays app usage"
GENAPIDOC__OPTION_LIST_DESC["--help|-h"]="
Displays app usage
"
GENAPIDOC__OPTION_LIST_ARGS["--help|-h"]="1"
GENAPIDOC__OPTION_LIST_ACTI["--help|-h"]=''

GENAPIDOC__OPTION_LIST_SDESC["--man"]="Displays the manual page"
GENAPIDOC__OPTION_LIST_DESC["--man"]="
Displays the manual page. The output can be used to generate regular MAN PAGES
"
GENAPIDOC__OPTION_LIST_ARGS["--man"]="1"
GENAPIDOC__OPTION_LIST_ACTI["--man"]=''


GENAPIDOC__OPTION_LIST_SDESC["-v|--version"]="Displays the app version"
GENAPIDOC__OPTION_LIST_DESC["-v|--version"]="
Displays the app version. The output can be used to generate regular debian packages
"
GENAPIDOC__OPTION_LIST_ARGS["-v|--version"]="1"
GENAPIDOC__OPTION_LIST_ACTI["-v|--version"]=''


:<<'EOF'
-y, -n, -v are additional options defined for convenience
EOF

GENAPIDOC__OPTION_LIST_SDESC["-y"]="Assume 'Yes' when prompted for confirmation"
GENAPIDOC__OPTION_LIST_DESC["-y"]="
Assume 'Yes' answer for any confirmation request
"
GENAPIDOC__OPTION_LIST_ARGS["-y"]="1"
GENAPIDOC__OPTION_LIST_ACTI["-y"]='Input__pushForcedInput "y"'


GENAPIDOC__OPTION_LIST_SDESC["-n"]="Assume 'No' when prompted for confirmation"
GENAPIDOC__OPTION_LIST_DESC["-n"]="
Assume 'No' answer for any confirmation request
"
GENAPIDOC__OPTION_LIST_ARGS["-n"]="1"
GENAPIDOC__OPTION_LIST_ACTI["-n"]='Input__pushForcedInput "y"'


GENAPIDOC__OPTION_LIST_SDESC["--verbose"]="Verbose mode"
GENAPIDOC__OPTION_LIST_DESC["--verbose"]="
Verbose mode. Shows messages additionally to those usually displayed.
"
GENAPIDOC__OPTION_LIST_ARGS["--verbose"]="1"
GENAPIDOC__OPTION_LIST_ACTI["--verbose"]='GENAPIDOC__VARS["verbose"]=true'


GENAPIDOC__OPTION_LIST_SDESC["--silent"]="Silent mode"
GENAPIDOC__OPTION_LIST_DESC["--silent"]="
Silent mode. Hides messages which are usually displayed even when verbose mode is not active.
"
GENAPIDOC__OPTION_LIST_ARGS["--silent"]="1"
GENAPIDOC__OPTION_LIST_ACTI["--silent"]='GENAPIDOC__VARS["silent"]=true'


GENAPIDOC__OPTION_LIST_SDESC["--debug"]="Activate debug logs"
GENAPIDOC__OPTION_LIST_DESC["--debug"]="
Activate debug logs
"
GENAPIDOC__OPTION_LIST_ARGS["--debug"]="1"
GENAPIDOC__OPTION_LIST_ACTI["--debug"]='__LOG_DEBUG__=0'


GENAPIDOC__OPTION_LIST_SDESC["--files"]="Lists all the files used by the app (config, log etc)"
GENAPIDOC__OPTION_LIST_DESC["--files"]="
Lists the files used by the app, i.e. the configuration file, the log file, the dependency system package installation cache file
"
GENAPIDOC__OPTION_LIST_ARGS["--files"]="1"
GENAPIDOC__OPTION_LIST_ACTI["--files"]='
local file
if _getConfigFilePath file ; then
        echo "${file}"
fi

if _getLogPath file ; then
        echo "${file}"
fi

if _getDependenciesCacheFile file ; then
        echo "${file}"
fi

_quit ""
'

GENAPIDOC__OPTION_LIST_SDESC["--log"]="Show the log tail"
GENAPIDOC__OPTION_LIST_DESC["--log"]="
Show the log tail. By default, shows the last 40 lines and the number of lines specified as option value.
"
GENAPIDOC__OPTION_LIST_ARGS["--log"]="2"
GENAPIDOC__OPTION_LIST_ACTI["--log"]='
local __log
_getLogPath __log
tail -F "${__log}" -n 40
_quit ""
'
GENAPIDOC__OPTION_LIST_VALS["--log"]='
local __log
_getLogPath __log
tail -F "${__log}" -n "${__myarg}"
_quit ""
'

GENAPIDOC__OPTION_LIST_SDESC["--config"]="Show the configuration file content"
GENAPIDOC__OPTION_LIST_DESC["--config"]="
Shows the configuration file content
"
GENAPIDOC__OPTION_LIST_ARGS["--config"]="1"
GENAPIDOC__OPTION_LIST_ACTI["--config"]='
local file
if _getConfigFilePath file ; then
        echo "${file}:"
        cat "${file}"
        echo "END"
        _quit ""
else
        _exit -1 "Failed to retrieve configuration file path"

fi 
'




GENAPIDOC__OPTION_LIST_SDESC["--doc"]="Specifies the output file for the generated online documentation"
GENAPIDOC__OPTION_LIST_DESC["--doc"]="
Specifies the output file for the generated online documentation
"
GENAPIDOC__OPTION_LIST_ARGS["--doc"]="0"
GENAPIDOC__OPTION_LIST_ARGS_TYPE["--doc"]="FILE"
GENAPIDOC__OPTION_LIST_ACTI["--doc"]=''
GENAPIDOC__OPTION_LIST_VALS["--doc"]='
GENAPIDOC__VARS["onlinedoc-file"]="${__myarg}"
echo > "${__myarg}"
'
