#!/bin/bash
###############################################################################
#
# Copyright (c) 2026 Michel Mehl. All rights reserved.
#
# -----------------------------------------------------------------------------
#
# A shell API of wrapper functions for running docker commands
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
Opens a mongoshell shell. Default host is 'localhost' when not specified. Default port is 27017 when not specified
@param[1] database name
@param[3] src host
@param[4] src port
EOF
mongodb__isRunning() {
	systemctl status mongod.service >/dev/null 2>"${__LOG_ERR_FILE__}"
}


:<<'EOF' 
Opens a mongoshell shell. Default host is 'localhost' when not specified. Default port is 27017 when not specified
@param[1] database name
@param[3] src host
@param[4] src port
EOF
mongodb__openShell() {
	_loadDep "mongodb-mongosh"

	local srcDb="$1"
	local srcHost="localhost"
	local srcPort=27017
	    
	if [ $# -ge 2 ] ; then
		srcHost="$2"
	fi
	if [ $# -ge 3 ] ; then
		srcPort="$3"
	fi

	#      mongosh mongodb://192.168.0.12:27018/slashetc


	local cmd="mongosh mongodb://${srcHost}:${srcPort}/${srcDb}"
	_logf "MONGODB COMMAND: ${cmd}" 

  	eval "$cmd"
}

:<<'EOF' 
Copies a database into another. Default host is 'localhost' when not specified. Default port is 27017 when not specified
@param[1] src database name
@param[2] dest database name
@param[3] optional src host
@param[4] optional src port
@param[5] optional dest host
@param[6] optional dest port
EOF
mongodb__duplicateDb() {
	local srcDb="$1"
	local dstDb="$2"
	local srcHost="localhost"
	local srcPort=27017
	local dstHost="localhost"
	local dstPort=27017
	    
	if [ $# -ge 3 ] ; then
		srcHost="$3"
	fi
	if [ $# -ge 4 ] ; then
		srcPort="$4"
	fi
	if [ $# -ge 5 ] ; then
		dstHost="$5"
	fi
	if [ $# -ge 6 ] ; then
		dstPort="$6"
	fi
	if Str__same "$srcDb" "$dstDb" ; then
		_log_err "${FUNCNAME[1]} : source and destination databases are the same ('$srcDb')"
		return 1
	fi

	local cmd="mongodump --archive --db='${srcDb}' --host='${srcHost}' --port=$srcPort | mongorestore --archive --nsFrom='${srcDb}.*' --nsTo='${dstDb}.*' --host='${dstHost}' --port=$dstPort"
	_logf "MONGODB COMMAND: ${cmd}" 

  	eval "$cmd"
}
