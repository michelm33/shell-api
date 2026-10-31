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
Tells whether the passed argument looks like an mongo URL, i.e.
of the basic form mongodb://<host>[:<port>][/<database name>]
Default port is 27017

example: mongodb://192.168.0.12:27018/slashetc

Safe characters: Alphanumeric [0-9a-zA-Z], special characters $-_.+!*'(),	No
Reserved characters	which are not allowed: / ? : @ = &	

@param [1] URL
@return 0 when valid URL, false (1) when not, <0 on arg error
EOF
mongodb__isURL() {
	local addr="$1"
    Str__toLower addr

	[[ "$addr" =~ ^mongodb:\/\/([^\/^:]+)(\:[0-9]+)?(\/[^\/]+)?$ ]]
}

:<<'EOF'
Decodes a mongo URL as accepted by mongodb__isURL

@param[1] URL
@param[3] out host
@param[2] out port 27017 when none specified by default
@param[2] out database name
@return 0 when valid URL, false (1) when not, <0 on arg error
EOF
mongodb__decodeURL() {
	local addr="$1"
	local -n __outHost=$2
	local -n __outPort=$3
	local -n __outDbName=$4
    
	Str__toLower addr
	if [[ "$addr" =~ ^mongodb:\/\/([^\/^:]+)(\:[0-9]+)?(\/[^\/]+)?$ ]] ; then
		__outHost="${BASH_REMATCH[1]}"
		__outPort="${BASH_REMATCH[2]:1}"
		if Str__isEmpty "${__outPort}" ; then
			__outPort=27017
		fi
		__outDbName="${BASH_REMATCH[3]:1}"
	else
		return 1
	fi
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

  	eval "$cmd" 2>> "${__LOG_ERR_FILE__}" 
}

:<<'EOF' 
Probes the opening of a mongoshell shell. This can be used to check if the mongodb is actually reachable
@param[1] database name
@param[3] src host
@param[4] src port
@return 0 is a shell could be opened, any other value otherwise
EOF

mongodb__probeShell() {
	mongodb__openShell "$1" "$2" "$3" <<< "quit" &>/dev/null 

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

  	eval "$cmd" 2>> "${__LOG_ERR_FILE__}" 
}



:<<'EOF' 
Dumps a MongoDB database as gzip archive from an URI, 
either to the specified file or on standard output 
when no file name/path is supplied.

NOTE: that the MongoDB archive format is a specific one, it is not
a tar.

IMPORTANT: When the dump is redirected to standard output, the metadata are not exported ! Therefore, a filename is always specified with the --archive option

@param[1] URL
@param[2] out file name
@param[3] Use SSH if the mongodb is located on a distance host
EOF
mongodb__dump() {
	local __inURL="$1"
	local __inOutputFilePath=""
	local __inOutputFileName=""
	local __inUseSSH=false
	local outRes=1

	if [ $# -ge 2 ] ; then
		__inOutputFilePath="$2"
		File__basename "${__inOutputFilePath}" __inOutputFileName
	fi
	if [ $# -ge 3 ] ; then
		__inUseSSH="$3"
	fi

	local host=""
	local port=""
	local dbName=""
	if ! mongodb__decodeURL "${__inURL}" host port dbName ; then
		_log_err "${FUNCNAME[0]}: invalid URI ${__inURL} "
		return 1
	fi

    local ipURI=""
    local hostnameURI=""
    Net__resolve "${host}" ipURI hostnameURI

    local myyip=""
    Net__getLocalHostIP myyip

	#_log_vars ipURI myyip __inUseSSH
	local cmd=""
	cmd="mongodump --uri='${__inURL}' --gzip --archive"
	local useSshWithFile=false
	if ! Str__same "$ipURI" "$myyip" && ${__inUseSSH} ; then
		local mylogin=""
		if ! User__getLogin mylogin ; then
			return 1
		fi

		# If a file is specified, cat the output file
		if [ $# -ge 2 ] ; then
			useSshWithFile=true
			cmd+="=\"${__inOutputFileName}\""
			cmd+="&& cat \"${__inOutputFileName}\""
		fi

		cmd="ssh ${mylogin}@${ipURI} '${cmd}'"

		if [ $# -ge 2 ] ; then
			cmd+="> '${__inOutputFilePath}'"
		fi
	else
		if [ $# -ge 2 ] ; then			
			cmd+="='${__inOutputFilePath}'" #NO, SEE COMMENT ABOVE: cmd+=" > '${__inOutputFilePath}'"
		fi
	fi

	_logf "MONGODB COMMAND: ${cmd}" 

  	eval "$cmd" 2>> "${__LOG_ERR_FILE__}" 
	outRes=$?
	if ! Int__not0 $outRes ; then
		if $useSshWithFile ; then 
			cmd="ssh ${mylogin}@${ipURI} rm -f '${__inOutputFileName}'"
			_logf "MONGODB COMMAND CLEANUP: ${cmd}" 
			eval "$cmd" 2>> "${__LOG_ERR_FILE__}" 
		fi
	fi
	return $outRes
}


:<<'EOF' 
Restores a MongoDB database of the specified URI from as gzip archive, 
either to the specified file or on standard output when no file name/path is supplied.

db name, host and port are extracted from the URI, whereby the following default options are used:
--archive --nsFrom=<dbName>.* --nsTo=<dbName}> --host=<host> --port=<port>

@param[1] URL
@param[2] in input dump file path
@param[3] mongorestore additional options (see mongorestore --help)
@param[4] Use SSH if the mongodb is located on a distance host
EOF
mongodb__restore() {
	local __inURL="$1"

	local __inInputFilePath=""
	local __inInputFileName=""
	if [ $# -ge 2 ] ; then
		__inInputFilePath="$2"
		File__basename "${__inInputFilePath}" __inInputFileName
	fi

	local cmdOptions=""
	if [ $# -ge 3 ] ; then
		cmdOptions="$3"
	fi

	local __inUseSSH=false
	if [ $# -ge 4 ] ; then
		__inUseSSH="$4"
	fi

	local host=""
	local port=""
	local dbName=""
	if ! mongodb__decodeURL "${__inURL}" host port dbName ; then
		_log_err "${FUNCNAME[0]}: invalid URI ${__inURL} "
		return 1
	fi

    local ipURI=""
    local hostnameURI=""
    Net__resolve "${host}" ipURI hostnameURI
    local myyip=""
    Net__getLocalHostIP myyip

	#_log_vars ipURI myyip __inUseSSH
	local cmd=""
	local cmdBaseRestore="mongorestore $cmdOptions --archive --nsFrom=\"${dbName}.*\" --nsTo=\"${dbName}.*\" --host=\"${host}\" --port=$port"
	local useSshWithFile=false
	if ! Str__same "$ipURI" "$myyip" && ${__inUseSSH} ; then
		local mylogin=""
		if ! User__getLogin mylogin ; then
			return 1
		fi
		cmdBaseRestore="ssh ${mylogin}@${ipURI} 'cat | ${cmdBaseRestore}'"
	fi

	_logf "MONGODB COMMAND: ${cmd}" 
	cmd="gunzip -c '${__inInputFilePath}' | ${cmdBaseRestore}" # -c is to output on stdout instead of unzipping and changing file itself
  	eval "$cmd" 2>> "${__LOG_ERR_FILE__}" 
}


:<<'EOF' 
Retrieves the mongodump tool version. When none could be found, each version number is set to "?"
@param[1] out ref to array var used to store each retrieved individual version number components (normally 3)
EOF

mongodb__dumpVersion() {
	local -n __inMajorVersionNumbers=$1
	local version=""
	read version< <(mongodump --version|head -n1|awk -F: '{print $2}')
	__inMajorVersionNumbers=()
	if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] ; then
		__inMajorVersionNumbers+=("${BASH_REMATCH[1]}")
		__inMajorVersionNumbers+=("${BASH_REMATCH[2]}")
		__inMajorVersionNumbers+=("${BASH_REMATCH[3]}")
	else
		__inMajorVersionNumbers=()
	fi
}

:<<'EOF' 
Stops the mongodb service using systemctl
EOF
mongodb__stop() {
	local cmd=""
	cmd="${__SUDO__}systemctl stop mongod"
	eval "$cmd"  2>> "${__LOG_ERR_FILE__}" 
}

:<<'EOF' 
Starts the mongodb service using systemctl
EOF
mongodb__start() {
	local cmd=""
	cmd="${__SUDO__}systemctl start mongod"
	eval "$cmd"  2>> "${__LOG_ERR_FILE__}" 
}

:<<'EOF' 
Tells whether the mongod daemon is running using systemctl
EOF
mongodb__isRunning() {
	local cmd=""
	# sudo systemctl status --plain -q -n 0 mongod.service	
	cmd="${__SUDO__}systemctl list-units -q mongod.service| awk '{print \$4}'"
	local state=""	
	read state < <(eval "$cmd"  2>> "${__LOG_ERR_FILE__}")
	#_log_vars state cmd
	[ "$state" = "running" ]

	# Former implementation:
	# systemctl status mongod.service >/dev/null 2>"${__LOG_ERR_FILE__}"
}

