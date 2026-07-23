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
# Release file path: genapp__help.sh
# Release file date: 2026-07-23 13:37
# App version: 1.1.0
# App source revision: 97
# App source signature: e20eb96b3d4e6835befb66ce8f066b37209f14602974b26a9ca3fd01599ac513
# Source file last modification: 2026-07-22 15:12:30.521355835 +0200
#
# This header was generated. Do not modify.
#
# ------------------------------------------------------------------------------
#
# This file contains the definition of all man and help functions.
#
# ------------------------------------------------------------------------------
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


Genapp__version() {

  local verfile="${GENAPP__VARS["MYDIR"]}/VERSION.txt"
  local revfile="${GENAPP__VARS["MYDIR"]}/REVISION.txt"
  local copyright="${GENAPP__VARS["MYDIR"]}/COPYRIGHT.txt"

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

Genapp__hash() {
  local revfile="${GENAPP__VARS["MYDIR"]}/REVISION.txt"

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


Genapp__versionnum() {
  local vfile="${GENAPP__VARS["MYDIR"]}/VERSION.txt"
  if [ -f "$vfile" ] ; then
cat << EOF
$(cat "$vfile")
EOF
  else
    echo "?"
  fi
}

Genapp__revision() {
  local revfile="${GENAPP__VARS["MYDIR"]}/REVISION.txt"

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

  local ctrlFlag=""
  if [ $# -gt 0 ] ; then
    ctrlFlag="$1"
  fi

cat << EOF
$(Genapp__susage_without_options)

OPTIONS:

$(_soptions GENAPP__OPTION_LIST_DESC GENAPP__OPTION_LIST_SDESC GENAPP__OPTION_LIST_ARGS GENAPP__OPTION_LIST_ARGS_TYPE GENAPP__OPTION_LIST_INTERN "" $ctrlFlag)

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

$(_soptions GENAPP__OPTION_LIST_DESC GENAPP__OPTION_LIST_SDESC GENAPP__OPTION_LIST_ARGS GENAPP__OPTION_LIST_ARGS_TYPE GENAPP__OPTION_LIST_INTERN "" "man")

*DESCRIPTION*

Genapp tool generates shell script app skeletons that build upon the shell-api library. The generated skeletons are immediately operational and ready for the app implementation. It will generate the following files:

- COPYRIGHT.txt : copyright notice

- LICENSE.txt: MIT by default, to be replaced if necessary

- CHANGELOG.txt: to be filled out as versions are released

- EXAMPLES.txt: List of examples. Indentation matters for manpage.

- <yourapp>__options.sh: file for managing options. For default ones, see doc.

- <yourapp>__help.h: file providing help functions.

- <yourapp>__vars.h: file containing the app-specific global variables

- <yourapp>: application skeleton

- pack/debian/control : for packaging with dpkg

$(_optionsN GENAPP__OPTION_LIST_DESC GENAPP__OPTION_LIST_ARGS GENAPP__OPTION_LIST_ARGS_TYPE GENAPP__OPTION_LIST_INTERN 0)
$(_optionsN GENAPP__OPTION_LIST_DESC GENAPP__OPTION_LIST_ARGS GENAPP__OPTION_LIST_ARGS_TYPE GENAPP__OPTION_LIST_INTERN 1)

*EXAMPLES*

$(Genapp__examples)

Report bugs to <michel.mehl@slashetc.fr>

EOF
}

