#!/bin/bash
# Run outside of riffian
WEBSITE_DIR=~/riffian/Data/Documents/professionnel/SlashEtc/siteweb
if [ ! -d "${WEBSITE_DIR}" ] ; then
    WEBSITE_DIR=~/Data/Documents/professionnel/SlashEtc/siteweb
fi

APIDOC="$(cat "${WEBSITE_DIR}/developertoolsforlinux/pages/_topics/shellapi/shellapi-functions.adoc" | sed 's/^=== /==== /g' | sed 's/^== /=== /g'  )" 
cat README.asciidoc.templ| \
awk -v APIDOC="${APIDOC}" '{
    if ($0=="//@shellapi-functions-adoc") {
     print APIDOC
    } else {
     print $0
    }
}' > README.asciidoc
echo "$PWD/README.asciidoc" was updated
