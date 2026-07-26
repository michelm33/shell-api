#!/bin/bash
###############################################################################
#
# MountPilot and SUMO backend control script
#
# Copyright (c) 2024-2026 Michel Mehl. All rights reserved.
#
# ------------------------------------------------------------------------------
#
# This updates the web download page for a new release
#
# ------------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
###############################################################################

usage()
{
    cat<<EOF >&2

$0 <web download page asciidoctor file> <product> <.deb package version> <.zip package version>

Example of deb package version:

    2.0-1
EOF

    exit -1
}

if [ $# -ne 4 ] ; then
    usage
fi

if [ ! -f "$1" ] ; then
    echo
    echo "'$1' is not a valid asciidoctor file"
    usage
fi

# This inserts the entry in the table when it does not exist yet (e.g. entered manualy or previously generated)
# To force regeneration, e.g. because format changed, erase then manually the line from there
newline="

"
read uploadTime < <(date +"%F %T %:::z %Z")
if [ -f "$1" ] ; then
echo $uploadTime
    cat "$1"| grep -F -v "${2}_${3}" | sed -E "s/\/\/@insert_new_balise/\/\/@insert_new_balise\n| Linux | link:https:\/\/slashetc.fr\/download\/${2}_${3}_amd64.deb\[${2}_${3}_amd64.deb\] | link:https:\/\/slashetc.fr\/download\/${2}_${4}.zip\[${2}_${4}.zip\] | ${uploadTime}/g" > "$1.tmp"
    mv "$1.tmp" "$1"
    echo "File '$1' was updated"
    exit 0
else
    echo "File '$1' does not exist !" >&2
    exit 1
fi