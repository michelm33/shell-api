#!/bin/bash
###############################################################################
#
# Copyright (c) 2024 Michel Mehl. All rights reserved.
#
# -----------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
# -----------------------------------------------------------------------------
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

    local xsltFile="$(mktemp).xslt"
    local newXML="$(mktemp)"
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

    local xsltFile="$(mktemp).xslt"
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


