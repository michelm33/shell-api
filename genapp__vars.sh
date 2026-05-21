#!/bin/bash
###############################################################################
#
# Genapp tool
#
# Copyright (c) 2026 Michel Mehl. All rights reserved.
#
# ------------------------------------------------------------------------------
#
# This file contains the definition of all internal variables used by Genapp.
# These variables may e.g. set by options and when reading data from a YAML file
#
# ------------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
###############################################################################

GENAPP__VARS["appname"]=""
GENAPP__VARS["appdirname"]=""
GENAPP__VARS["author"]=""
GENAPP__VARS["email"]=""
GENAPP__VARS["rootreleasedir"]=""
GENAPP__VARS["http"]=""
GENAPP__VARS["githubid"]=""
GENAPP__VARS["appdesc"]=""


:<<'EOF'
# Sample dummy var definition that can be used as template
GENAPP__VARS["myvarname"]=""
EOF