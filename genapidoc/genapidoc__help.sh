#!/bin/bash
###############################################################################
#
# Genapidoc
#
# Copyright (c) 2026 Michel MEHL. All rights reserved.
#
# ------------------------------------------------------------------------------
#
# This file contains the definition of all usage, help and documentation functions.
#
# ------------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
###############################################################################

Genapidoc__version() {

  local verfile="${GENAPIDOC__VARS["MYDIR"]}/VERSION.txt"
  local revfile="${GENAPIDOC__VARS["MYDIR"]}/REVISION.txt"
  local copyright="${GENAPIDOC__VARS["MYDIR"]}/COPYRIGHT.txt"

  # Version info
  # Version file contains one line giving the version x.y.z
  echo -n "${__SHELL_CURRENT_APPNAME__} "
  if [ -f "${verfile}" ] ;  then
    cat "${verfile}"
  else
    echo "?.?.?"
  fi
  
  # Revision info if any
  # Revision file contains 2 lines
  # Line 1: the revision number in the configuration management system
  # Line 2: a signature like a hash code computed over the source files 
  if [ -f "${revfile}" ] ;  then
    echo -n "Revision "
    local line
    local cnt=0
    while IFS=''  read -r line
    do
      if [ $cnt -eq 0 ] ; then
        echo -n "$line"
      elif [ $cnt -eq 1 ] ; then
        echo -n " signed $line"
      fi
      cnt=$(($cnt + 1))
    done < <(cat "${revfile}")

    if [ $cnt -eq 1 ] ; then
          echo -n " (unsigned)"
    fi    
    echo
  fi

  # Copyright
  # The trailing line from 4th line are displayed
  if [ -f "${copyright}" ] ;  then
    echo
    local content="$(cat "${copyright}")"
    echo "${content}"|tail -n+3
  fi

  # Author
  # Author fullname is retrieved from passwd
  local fnUser=""
  User__getFullUserName fnUser
cat<<EOF

Written by ${fnUser}

EOF
}

Genapidoc__revision() {
  local revfile="${GENAPIDOC__VARS["MYDIR"]}/REVISION.txt"

  # Revision info if any
  if [ -f "${revfile}" ] ;  then
    local line
    local __lcnt=0
    local revisionnum=""
    while IFS=''  read -r line
    do
      if [ ${__lcnt} -eq 0 ] ; then
        revisionnum="$line"
        break
      fi
      __lcnt=$((${__lcnt} + 1))
    done < <(cat "${revfile}")

    if [ -z "$revisionnum" ] ; then
      echo "?"
    else
      echo "$revisionnum"
    fi
  else
    echo "?"
  fi
}

Genapidoc__hash() {
  local revfile="${GENAPIDOC__VARS["MYDIR"]}/REVISION.txt"

  # Revision info if any
  if [ -f "${revfile}" ] ;  then
    local line
    local __lcnt=0
    local hashcode=""
    while IFS=''  read -r line
    do
      if [ ${__lcnt} -eq 1 ] ; then
        hashcode="$line"
        break
      fi
      __lcnt=$((${__lcnt} + 1))
    done < <(cat "${revfile}")

    if [ -z "$hashcode" ] ; then
      echo "?"
    else
      echo "$hashcode"
    fi
  else
    echo "?"
  fi
}

Genapidoc__versionnum() {
  local vfile="${GENAPIDOC__VARS["MYDIR"]}/VERSION.txt"
  if [ -f "$vfile" ] ; then
cat << EOF
$(cat "$vfile")
EOF
  else
    echo "?"
  fi
}

:<<'EOF'
Help display callback (-h) for usage
EOF

Genapidoc__help() {
  echo
  Genapidoc__usage
}

:<<'EOF'
Short usage display callback without the option details
EOF

Genapidoc__susage_without_options() {
  local __cmdbasename="$(basename $0)"
cat << EOF
Usage: ${__cmdbasename} OPTIONS [<sample usage arg>]
or: ${__cmdbasename} OPTIONS [<sample usage arg 2>]
EOF
}

:<<'EOF'
Usage display callback 
EOF

Genapidoc__susage() {

  local ctrlFlag=""
  if [ $# -gt 0 ] ; then
    ctrlFlag="$1"
  fi

cat << EOF
$(Genapidoc__susage_without_options)

OPTIONS:

$(_soptions GENAPIDOC__OPTION_LIST_DESC GENAPIDOC__OPTION_LIST_SDESC GENAPIDOC__OPTION_LIST_ARGS GENAPIDOC__OPTION_LIST_ARGS_TYPE GENAPIDOC__OPTION_LIST_INTERN "" $ctrlFlag)

EOF
}

Genapidoc__usage_args() {
cat << EOF

Arguments:

 <sample arg>       put your argument short description here. Copy/paste in new line and change for additional ones.

EOF
}

:<<'EOF'
Usage display callback 
EOF

Genapidoc__usage() {
cat << EOF
$(Genapidoc__susage)
$(Genapidoc__usage_args)

EOF
}

Genapidoc__examples() {
  local exampleFile="${GENAPIDOC__VARS["MYDIR"]}/EXAMPLES.txt"
  if [ -f "${exampleFile}" ] ; then
    cat "${exampleFile}"
  fi
}

Genapidoc__man() {
cat << EOF | less
*SYNOPSIS*

$(Genapidoc__susage_without_options)
$(Genapidoc__usage_args)

OPTIONS:

$(_soptions GENAPIDOC__OPTION_LIST_DESC GENAPIDOC__OPTION_LIST_SDESC GENAPIDOC__OPTION_LIST_ARGS GENAPIDOC__OPTION_LIST_ARGS_TYPE GENAPIDOC__OPTION_LIST_INTERN "" "man")

*DESCRIPTION*

Put your description here

*EXAMPLES*

$(Genapidoc__examples)

Report bugs to <michel.mehl@slashetc.fr>

EOF
}

