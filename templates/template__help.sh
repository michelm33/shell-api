#!/bin/bash
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
Usage: ${__cmdbasename} OPTIONS [<sample usage arg>]
or: ${__cmdbasename} OPTIONS [<sample usage arg 2>]
EOF
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

$(_soptions GENAPP__OPTION_LIST_DESC GENAPP__OPTION_LIST_SDESC GENAPP__OPTION_LIST_ARGS GENAPP__OPTION_LIST_ARGS_TYPE GENAPP__OPTION_LIST_INTERN "" "man")

*DESCRIPTION*

Put your description here

*EXAMPLES*

$(Genapp__examples)

Report bugs to <michel.mehl@slashetc.fr>

EOF
}

