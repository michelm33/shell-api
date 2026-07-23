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
# Release file path: genapp__options.sh
# Release file date: 2026-07-23 13:37
# App version: 1.1.0
# App source revision: 97
# App source signature: e20eb96b3d4e6835befb66ce8f066b37209f14602974b26a9ca3fd01599ac513
# Source file last modification: 2026-06-10 17:00:25.183755313 +0200
#
# This header was generated. Do not modify.
#
# ------------------------------------------------------------------------------
#
# This file contains the definition of all options supported by Genapp.
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

GENAPP__OPTION_LIST_SDESC["--help|-h"]="Display Genapp usage"
GENAPP__OPTION_LIST_DESC["--help|-h"]="
Displays Genapp usage
"
GENAPP__OPTION_LIST_ARGS["--help|-h"]="1"
GENAPP__OPTION_LIST_ACTI["--help|-h"]=''

GENAPP__OPTION_LIST_SDESC["--man"]="Display the Genapp manual page"
GENAPP__OPTION_LIST_DESC["--man"]="
Displays the Genapp manual page. The output can be used to generate regular MAN PAGES
"
GENAPP__OPTION_LIST_ARGS["--man"]="1"
GENAPP__OPTION_LIST_ACTI["--man"]=''


GENAPP__OPTION_LIST_SDESC["-v|--version"]="Display the Genapp version"
GENAPP__OPTION_LIST_DESC["-v|--version"]="
Displays the Genapp version. The output can be used to generate regular debian packages
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



GENAPP__OPTION_LIST_SDESC["--root-release-dir"]="software release folder for the generated app"
GENAPP__OPTION_LIST_DESC["--root-release-dir"]="
Specifies the path to the root folder where are stored software release for the generated app.
The folder path shall be relative to the application source folder. 
A subfolder will be created below the release folder for the generated app, 
therefore the release folder can be used for other apps as well. 
"
GENAPP__OPTION_LIST_ARGS["--root-release-dir"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--root-release-dir"]="<FOLDER PATH>"
GENAPP__OPTION_LIST_ACTI["--root-release-dir"]=""
GENAPP__OPTION_LIST_VALS["--root-release-dir"]='
        GENAPP__VARS["rootreleasedir"]="${__myarg}" 
'

GENAPP__OPTION_LIST_SDESC["--http"]="URL for the debian package homepage of the app to generate"
GENAPP__OPTION_LIST_DESC["--http"]="
Specifies the URL for the debian package homepage of the generated app.
If none is supplied the default URL is https://github/<github user id>/<appname>,
where <github user id> is specified with --github-id
"
GENAPP__OPTION_LIST_ARGS["--http"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--http"]="<URL>"
GENAPP__OPTION_LIST_ACTI["--http"]=""
GENAPP__OPTION_LIST_VALS["--http"]='
        GENAPP__VARS["http"]="${__myarg}" 
'

GENAPP__OPTION_LIST_SDESC["--desc"]="Description of the app to generate"
GENAPP__OPTION_LIST_DESC["--desc"]="
Supplies a description of the app to generate
"
GENAPP__OPTION_LIST_ARGS["--desc"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--desc"]="<TEXTE>"
GENAPP__OPTION_LIST_ACTI["--desc"]=""
GENAPP__OPTION_LIST_VALS["--desc"]='
        GENAPP__VARS["appdesc"]="${__myarg}" 
'


GENAPP__OPTION_LIST_SDESC["--github-id"]="User id to use to build the github URL for the debian package homepage definition of the generated app"
GENAPP__OPTION_LIST_DESC["--github-id"]="
Supplies the github id to use to build https github URL for the debian package when --http is not specified
"
GENAPP__OPTION_LIST_ARGS["--github-id"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--github-id"]="<TEXTE>"
GENAPP__OPTION_LIST_ACTI["--github-id"]=""
GENAPP__OPTION_LIST_VALS["--github-id"]='
        GENAPP__VARS["githubid"]="${__myarg}" 
'

GENAPP__OPTION_LIST_SDESC["--author"]="Author of the app to generate"
GENAPP__OPTION_LIST_DESC["--author"]="
Specifies the author of the generated app as it will appear in the source file headers, copyright notices and debian packages
"
GENAPP__OPTION_LIST_ARGS["--author"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--author"]="<TEXTE>"
GENAPP__OPTION_LIST_ACTI["--author"]=""
GENAPP__OPTION_LIST_VALS["--author"]='
        GENAPP__VARS["author"]="${__myarg}" 
'

GENAPP__OPTION_LIST_SDESC["--email"]="Official contact email for the app to generate"
GENAPP__OPTION_LIST_DESC["--email"]="
Specifies the generated app's official contact email, typically the author's one, as it will appear in the source file headers, copyright notices and debian packages
"
GENAPP__OPTION_LIST_ARGS["--email"]="0" 
GENAPP__OPTION_LIST_ARGS_TYPE["--email"]="<TEXTE>"
GENAPP__OPTION_LIST_ACTI["--email"]=""
GENAPP__OPTION_LIST_VALS["--email"]='
        GENAPP__VARS["email"]="${__myarg}" 
'

GENAPP__OPTION_LIST_SDESC["--config"]="Show the configuration file content"
GENAPP__OPTION_LIST_DESC["--config"]="
Shows the configuration file content
"
GENAPP__OPTION_LIST_ARGS["--config"]="1"
GENAPP__OPTION_LIST_ACTI["--config"]='
local file
if _getConfigFilePath file ; then
        cat "${file}"
fi 
'
