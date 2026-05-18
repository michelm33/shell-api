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
Usage: ${__cmdbasename} OPTIONS <sample arg>]
or: ${__cmdbasename} OPTIONS [<sample arg 2>]  
EOF
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

 <sample arg>       put your argument short description here. Copy/paste in new line and change for additional ones.

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

Put your description here

*EXAMPLES*

$(Genapp__examples)

Report bugs to <michel.mehl@slashetc.fr>

EOF
}

