#!/bin/bash
###############################################################################
#
# Copyright (c) 2026 Michel Mehl. All rights reserved.
#
# -----------------------------------------------------------------------------
#
# A shell API of wrapper functions for running git commands
#
# -----------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
###############################################################################

__SHELL_API_DEV_DIR__=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

source "${__SHELL_API_DEV_DIR__}/shell-api-core.sh"

if _loaded "${BASH_SOURCE[0]}"  ; then
	return 0
fi

:<<'EOF' 
Tags the last commit
@param[1] tag string
@param[2] tag log message
@param[3] optional bool telling whether to replace any previous tag of the same name. False by default
@param[4] optional bool telling whether to push tag changes. True by default

EOF
git__tag() {
	local __inTagName="$1"
	local __inTagLog="$2"
	local __inDoReplace=false
	local __inDoPush=true
	local lastCommitHash=""
	
	if [ $# -ge 3 ] ; then
		__inDoReplace=$3
	fi

	if [ $# -ge 4 ] ; then
		__inDoPush=$4
	fi


	lastCommitHash=$(git rev-parse HEAD 2>/dev/null)
	if [ $? -ne 0 ] ; then
		_log_err "${FUNCNAME[0]}: failed to retrieve hash of last commit. You may not be in a git folder"
		return 1
	fi

	local cmd="git tag -a '${__inTagName}' -m '${__inTagLog}' '$lastCommitHash'"	 
	_logf "GIT COMMAND: ${cmd}" 
	local ret=1
	eval "$cmd" 2>> "${__LOG_ERR_FILE__}" >/dev/null
	ret=$?
	if [ $ret -ne 0 ] && ${__inDoReplace} ; then
		_log_dbg "-- Deleting tag ${__inTagName}"
		cmd="git tag -d '${__inTagName}'"
		_logf "GIT COMMAND: ${cmd}" 
		if eval "$cmd" 2>> "${__LOG_ERR_FILE__}" >/dev/null; then
			if ${__inDoPush} ; then
				# remove old tag on origin
				cmd="git push origin :refs/tags/${__inTagName}"
				_logf "GIT COMMAND: ${cmd}" 
				if ! eval "$cmd" 2>> "${__LOG_ERR_FILE__}" >/dev/null; then
					_log_warn "${FUNCNAME[0]}: failed to push removal of tag '${__inTagName} on origin"
				fi
			fi

			# Re try
			git__tag "${__inTagName}" "${__inTagLog}" false ${__inDoPush}
			return $?
		else
			_log_err "${FUNCNAME[0]}: failed to delete previous tag '${__inTagName}'"
			return 1
		fi
	fi

	if [ $ret -eq 0 ] && ${__inDoPush} ; then
		# push new one on origin 
		cmd="git push origin refs/tags/${__inTagName}" 
		_logf "GIT COMMAND: ${cmd}" 
		if ! eval "$cmd" 2>> "${__LOG_ERR_FILE__}" >/dev/null; then
			_log_warn "${FUNCNAME[0]}: failed to push tag '${__inTagName} on origin"
		fi
	fi

	return $ret
}


