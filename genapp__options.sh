#!/bin/bash
###############################################################################
#
# Genapp tool
#
# Copyright (c) 2026 Michel Mehl. All rights reserved.
#
# ------------------------------------------------------------------------------
#
# This file contains the definition of all options supported by Genapp.
#
# ------------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
###############################################################################

# Keys are option alternatives separated by |
declare -A GENAPP__OPTION_LIST_SDESC # Option short description 
declare -A GENAPP__OPTION_LIST_DESC # Option description
declare -A GENAPP__OPTION_LIST_ARGS # Tells whether arg expected or none
declare -A GENAPP__OPTION_LIST_ARGS_TYPE # Give the type of the argument(s)
declare -A GENAPP__OPTION_LIST_VALS # Executed code when processing an expected arg
declare -A GENAPP__OPTION_LIST_ACTI # Executed code when option is detected
declare -A GENAPP__OPTION_LIST_INTERN # Tells whether the option is not intended for end-users or only for advanced ones

:<<'EOF'
-h, -v, --man are standard options
EOF

GENAPP__OPTION_LIST_SDESC["--help|-h"]="Displays app usage"
GENAPP__OPTION_LIST_DESC["--help|-h"]="
Displays app usage
"
GENAPP__OPTION_LIST_ARGS["--help|-h"]="1"
GENAPP__OPTION_LIST_ACTI["--help|-h"]=''

GENAPP__OPTION_LIST_SDESC["--man"]="Displays the manual page"
GENAPP__OPTION_LIST_DESC["--man"]="
Displays the manual page. The output can be used to generate regular MAN PAGES
"
GENAPP__OPTION_LIST_ARGS["--man"]="1"
GENAPP__OPTION_LIST_ACTI["--man"]=''


GENAPP__OPTION_LIST_SDESC["-v|--version"]="Displays the app version"
GENAPP__OPTION_LIST_DESC["-v|--version"]="
Displays the app version. The output can be used to generate regular debian packages
"
GENAPP__OPTION_LIST_ARGS["-v|--version"]="1"
GENAPP__OPTION_LIST_ACTI["-v|--version"]=''


:<<'EOF'
-y, -v are additional options defined for convenience
EOF

GENAPP__OPTION_LIST_SDESC["-y"]="Assume 'Yes' when prompted for confirmation"
GENAPP__OPTION_LIST_DESC["-y"]="
Assume 'Yes' answer for any confirmation request
"
GENAPP__OPTION_LIST_ARGS["-y"]="1"
GENAPP__OPTION_LIST_ACTI["-y"]='Input__pushForcedInput "y"'


GENAPP__OPTION_LIST_SDESC["--verbose"]="Verbose mode"
GENAPP__OPTION_LIST_DESC["--verbose"]="
Verbose mode
"
GENAPP__OPTION_LIST_ARGS["--verbose"]="1"
GENAPP__OPTION_LIST_ACTI["--verbose"]='GENAPP__VARS["verbose"]=true'



GENAPP__OPTION_LIST_SDESC["--root-release-dir"]="Path to the root folder where are stored software release"
GENAPP__OPTION_LIST_DESC["--root-release-dir"]="
Specifies the path to the root folder where are stored software release

The folder path shall be relative to the application source folder.
"
GENAPP__OPTION_LIST_ARGS["--root-release-dir"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--root-release-dir"]="<FOLDER PATH>"
GENAPP__OPTION_LIST_ACTI["--root-release-dir"]=""
GENAPP__OPTION_LIST_VALS["--root-release-dir"]='
        GENAPP__VARS["rootreleasedir"]="${__myarg}" 
'

GENAPP__OPTION_LIST_SDESC["--http"]="URL for the debian package homepage of the app"
GENAPP__OPTION_LIST_DESC["--http"]="
Specifies the URL for the debian package homepage of the app.
If none is supplied the default URL is https://github/<github user id>/<appname>,
where <github user id> is specified with --github-id
"
GENAPP__OPTION_LIST_ARGS["--http"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--http"]="<URL>"
GENAPP__OPTION_LIST_ACTI["--http"]=""
GENAPP__OPTION_LIST_VALS["--http"]='
        GENAPP__VARS["http"]="${__myarg}" 
'

GENAPP__OPTION_LIST_SDESC["--desc"]="Description of the app"
GENAPP__OPTION_LIST_DESC["--desc"]="
Supplies a description of the app
"
GENAPP__OPTION_LIST_ARGS["--desc"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--desc"]="<TEXTE>"
GENAPP__OPTION_LIST_ACTI["--desc"]=""
GENAPP__OPTION_LIST_VALS["--desc"]='
        GENAPP__VARS["appdesc"]="${__myarg}" 
'


GENAPP__OPTION_LIST_SDESC["--github-id"]="User id to use to build the github URL for the debian package homepage definition"
GENAPP__OPTION_LIST_DESC["--github-id"]="
Supplies the github id to use to build https github URL for the debian package when --http is not specified
"
GENAPP__OPTION_LIST_ARGS["--github-id"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--github-id"]="<TEXTE>"
GENAPP__OPTION_LIST_ACTI["--github-id"]=""
GENAPP__OPTION_LIST_VALS["--github-id"]='
        GENAPP__VARS["githubid"]="${__myarg}" 
'

GENAPP__OPTION_LIST_SDESC["--author"]="Author of the app"
GENAPP__OPTION_LIST_DESC["--author"]="
Specifies the author of the app as it will appear in the source file headers, copyright notices and debian packages
"
GENAPP__OPTION_LIST_ARGS["--author"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--author"]="<TEXTE>"
GENAPP__OPTION_LIST_ACTI["--author"]=""
GENAPP__OPTION_LIST_VALS["--author"]='
        GENAPP__VARS["author"]="${__myarg}" 
'

GENAPP__OPTION_LIST_SDESC["--email"]="app's official contact email"
GENAPP__OPTION_LIST_DESC["--email"]="
Specifies the app's official contact email, typically the author's one, as it will appear in the source file headers, copyright notices and debian packages
"
GENAPP__OPTION_LIST_ARGS["--email"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--email"]="<TEXTE>"
GENAPP__OPTION_LIST_ACTI["--email"]=""
GENAPP__OPTION_LIST_VALS["--email"]='
        GENAPP__VARS["email"]="${__myarg}" 
'
