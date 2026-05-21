#!/bin/bash

Genapp__version() {
cat << EOF
${__SHELL_CURRENT_APPNAME__} $(cat "${GENAPP__VARS["MYDIR"]}/VERSION.txt")

$(cat "${GENAPP__VARS["MYDIR"]}/COPYRIGHT.txt"|tail -n+4)

Written by Michel Mehl

EOF
}

:<<'EOF'
Help display callback (-h) for usage
EOF

Genapp__help() {
  echo
  Genapp__usage
}

:<<'EOF'
Short usage display callback without the option details
EOF

Genapp__susage_without_options() {
  local __cmdbasename="$(basename $0)"
cat << EOF
Usage: ${__cmdbasename} OPTIONS <application name>
EOF
#or: ${__cmdbasename} OPTIONS [<sample arg 2>]  
}

:<<'EOF'
Usage display callback 
EOF

Genapp__susage() {
cat << EOF
$(Genapp__susage_without_options)

OPTIONS:

$(_soptions GENAPP__OPTION_LIST_DESC GENAPP__OPTION_LIST_SDESC GENAPP__OPTION_LIST_ARGS GENAPP__OPTION_LIST_ARGS_TYPE GENAPP__OPTION_LIST_INTERN)

EOF
}

Genapp__usage_args() {
cat << EOF

Arguments:

 <application name>  a word identifying the app, starting with an uppercase (will be enforced)

EOF
}

:<<'EOF'
Usage display callback 
EOF

Genapp__usage() {
cat << EOF
$(Genapp__susage)
$(Genapp__usage_args)

EOF
}

Genapp__examples() {
  local exampleFile="${GENAPP__VARS["MYDIR"]}/EXAMPLES.txt"
  if [ -f "${exampleFile}" ] ; then
    cat "${exampleFile}"
  fi
}

Genapp__man() {
cat << EOF | less
*SYNOPSIS*

$(Genapp__susage_without_options)
$(Genapp__usage_args)

OPTIONS:

$(_soptions GENAPP__OPTION_LIST_DESC GENAPP__OPTION_LIST_SDESC GENAPP__OPTION_LIST_ARGS GENAPP__OPTION_LIST_ARGS_TYPE GENAPP__OPTION_LIST_INTERN)

*DESCRIPTION*

Genapp tool generates shell script app skeletons based the shell-api library. The generated skeletons are immediately operational and just need to be 
adapted to the specific app to be implemented. It will generate the following files:

- COPYRIGHT.txt 

- LICENSE.txt: MIT by default, to be replaced if necessary

- CHANGELOG.txt: to be filled out as versions are released

- EXAMPLES: a template 

- <yourapp>__options.sh: skeleton file for managing options, by default includes -h|--help, --man, -v|--version, --verbose, -y

- <yourapp>__help.h: skeleton file providing help functions to enable packaging with dpkg

- <yourapp>__vars.h: skeleton file (empty) to be used for providing app-specific global variable definitions

- <yourapp>: application skeleton, including all the above ones

- pack/debian/control : for packaging with dpkg


*EXAMPLES*

$(Genapp__examples)

Report bugs to <michel.mehl@slashetc.fr>

EOF
}

