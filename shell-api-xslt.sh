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
# Release file path: shell-api-xslt.sh
# Release file date: 2026-07-23 13:37
# App version: 1.1.0
# App source revision: 97
# App source signature: e20eb96b3d4e6835befb66ce8f066b37209f14602974b26a9ca3fd01599ac513
# Source file last modification: 2026-07-05 18:58:56.711248556 +0200
#
# This header was generated. Do not modify.
#
# -----------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
# -----------------------------------------------------------------------------
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

__SHELL_API_XSLT_DIR__=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

source "${__SHELL_API_XSLT_DIR__}/shell-api-core.sh"

if _loaded "${BASH_SOURCE[0]}"  ; then
	return 0
fi

:<<EOF
EOF

XSLT__modifyXML() {
    local sourceXML="$1"
    local transformCode="$2"
    shift 2
    #_log "XSLT__modifyXML : ALL ARGS: $@"
    local parameters=() #=($@) # Init directly caused a problem with arg forwardlink:<url>
    while [ $# -gt 0 ] ; do
        parameters+=("$1")
        shift
    done
    local paramNames=()
    local paramValues=()
    local i
    local xsltCmdLineParams=()
    local xsltCodeParams=()
    #_log "XSLT__modifyXML remaining args: ${parameters[@]}"
    for p in "${parameters[@]}" ; do
        local paramName
        local paramValue
        Str__split "$p" paramName ":" paramValue 1
        paramNames+=("$paramName")
        paramValues+=("$paramValue")
        xsltCmdLineParams+=(" --stringparam ${paramName} '${paramValue}'")
        xsltCodeParams+=(" <xsl:param name=\"${paramName}\" select=\"''\"/>")
    done

    local xsltFile=""
    local newXML=""
    File__createTempFile xsltFile xslt
    File__createTempFile newXML

    #local escapedTransformCode="$(echo "$transformCode"|sed -E 's/"/\\"/g')"
    cat<<EOF > "${xsltFile}"
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
<xsl:template match="@*|node()">
  <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
   </xsl:copy>
</xsl:template>
${xsltCodeParams[@]}
${transformCode}
</xsl:stylesheet>
EOF
    #echo "${transformCode}" >> "${xsltFile}"
    #echo "</xsl:stylesheet>"  >> "${xsltFile}"
    #_log "XSLT file content '${xsltFile}'"
    #cat "${xsltFile}"
    #return 0
    local cmd="xsltproc --path . ${xsltCmdLineParams[@]} \"${xsltFile}\" \"${sourceXML}\""
    #_log "Executing $cmd"
	#xsltproc --path "." ${xsltCmdLineParams[@]} "${xsltFile}" "${sourceXML}" > "${newXML}" 
    _logf "COMMAND: '$cmd'"
    eval "$cmd" > "${newXML}" 
    if [ $? -eq 0 ] ; then
        mv "${newXML}" "${sourceXML}" 
    else
        rm "${newXML}"
    fi
    rm "${xsltFile}"
}

# NOT TESTED
#
XSLT__transformToText() {
    local sourceXML="$1"
    local transformCode="$2"
    local -n __out_result=$3
    shift 2
    #_log "XSLT__modifyXML : ALL ARGS: $@"
    local parameters=() #=($@) # Init directly caused a problem with arg forwardlink:<url>
    while [ $# -gt 0 ] ; do
        parameters+=("$1")
        shift
    done
    local paramNames=()
    local paramValues=()
    local i
    local xsltCmdLineParams=()
    local xsltCodeParams=()
    #_log "XSLT__modifyXML remaining args: ${parameters[@]}"
    for p in "${parameters[@]}" ; do
        local paramName
        local paramValue
        Str__split "$p" paramName ":" paramValue 1
        paramNames+=("$paramName")
        paramValues+=("$paramValue")
        xsltCmdLineParams+=(" --stringparam ${paramName} '${paramValue}'")
        xsltCodeParams+=(" <xsl:param name=\"${paramName}\" select=\"''\"/>")
    done

    local xsltFile=""
    File__createTempFile xsltFile xslt

    #local escapedTransformCode="$(echo "$transformCode"|sed -E 's/"/\\"/g')"
    cat<<EOF > "${xsltFile}"
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:template match="@*|node()">
  <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
   </xsl:copy>
</xsl:template>
${xsltCodeParams[@]}
${transformCode}
</xsl:stylesheet>
EOF
    local cmd="xsltproc --path . ${xsltCmdLineParams[@]} \"${xsltFile}\" \"${sourceXML}\""
    #_log "Executing $cmd"
	#xsltproc --path "." ${xsltCmdLineParams[@]} "${xsltFile}" "${sourceXML}" > "${newXML}" 
    _logf "COMMAND: '$cmd'"
    __out_result="$(eval "$cmd" > "${newXML}")"
    rm "${xsltFile}"
}


