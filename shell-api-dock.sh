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
Tells whether the passed argument looks like a docker URL, i.e.
of the basic form dock://<host>/<image name>

example: dock://192.168.0.12/wwwserver

@param[1] URL
@return 0 when valid URL, false (1) when not, <0 on arg error
EOF
dock__isURL() {
	local addr="$1"
    Str__toLower addr

	[[ "$addr" =~ ^dock:\/\/([^\/]+)(\/[^\/]+)$ ]]
}

:<<'EOF'
Decodes a docker URL as accepted by dock__isURL
example: dock://192.168.0.12/publiwwwserver

@param[1] URL
@param[2] out image
@param[3] out host
@return 0 when valid URL, false (1) when not, <0 on arg error
EOF
dock__decodeURL() {
	local addr="$1"
	local -n __outImage=$2
	local -n __outHost=$3
    Str__toLower addr

	if [[ "$addr" =~ ^dock:\/\/([^\/]+)(\/[^\/]+)$ ]] ; then
		__outImage="${BASH_REMATCH[2]:1}"
		__outHost="${BASH_REMATCH[1]}"
	else
		return 1
	fi
}

:<<'EOF' 
Retrieves the SHA256 id of the last committed image from a passed image.

If the argument may be a docker URL, the image name will be extracted from it.
However, the host part is ignored at the moment and the image is assumed to be local.
@param[1] name of docker image
@param[2] 
EOF
dock__lastImageId() {
	local __inImageName="$1"
	local -n __outImageId=$2
	 
	if dock__isURL "${__inImageName}" ; then
		local dockHost=""
		dock__decodeURL "${__inImageName}"  __inImageName dockHost
	fi

	local cmd="docker history -q '${__inImageName}' | head -n1"

	_logf "DOCKER COMMAND: ${cmd}" 
	read __outImageId < <(eval "$cmd")

}

:<<'EOF' 
Fills the passed array with the names of actual running containers.
EOF
dock__ps() {
	local -n __outContainerNames=$1
	local cmd="docker ps -a| awk '{ if (NR > 1) printf(\"%s \", \$NF)}'"
	 
	_logf "DOCKER COMMAND: ${cmd}" 
	__outContainerNames=($(eval "$cmd"))
}


:<<'EOF' 
Tells whether the passed container is running
EOF
dock__isRunning() {
	local containerName="$1"
  	[ "$( ${__SUDO__}docker container inspect -f '{{.State.Status}}' "${containerName}" 2>/dev/null)" = "running" ]
	
}

:<<'EOF' 
Opens a shell in the passed existing container
EOF
dock__openShell() {
	local containerName="$1"
	local cmd=""
  	cmd="${__SUDO__}docker"
	cmd+=" exec -it '${containerName}' /bin/bash"
  	eval "$cmd"
}

:<<'EOF' 
Executes a 'run' docker command
@param[1] image name
@param[2] container name
@param[3] a ref to a map giving option values (key=option name, value=option value).
          Supported values: 
		    'interactive' :(true/false) : if true, adds '--it' as command option,
		  	'privileged' (true/false) : if true, adds '--privileged'  as command option,
			'lan'  (true/false) : if true, adds '--net host' as command option, meaning container has access to the local LAN
@param[4] a ref to a map giving environment variable value (key=var name, value=value)
@param[5] a ref to a map giving mount mappings (key=src folder, value=destination)
EOF
dock__run() {
	local containerImage="$1"
	local containerName="$2"
	local -n containerOpt=$3
	local -n containerEnv=$4
	local -n containerMounts=$5
	
	local cmd=""
  	cmd="${__SUDO__}docker"
	cmd+=" run --rm"

	if [ "${containerOpt["interactive"]}" = true ] ; then
		cmd+=" -it"
	fi
	if [ "${containerOpt["privileged"]}" = true ] ; then
		cmd+=" --privileged"
	fi
	if [ "${containerOpt["lan"]}" = true ] ; then
		cmd+=" --net host"
	fi

	local K=""
	for K in "${!containerEnv[@]}" ; do
		cmd+=" -e '${K}=${containerEnv["$K"]}'"
	done
	for K in "${!containerMounts[@]}" ; do
		cmd+=" --mount type=bind,src='$K',dst='${containerMounts["$K"]}'"
	done
    #--user $(id -u):$(id -g) -w /home/ubuntu \
    #-e TZ="Europe/Paris" \
	#-p 3006:3006 -p 8080:8080

	cmd+=" --name '${containerName}' '${containerImage}'"
	_logf "DOCKER COMMAND: ${cmd}" 
  	eval "$cmd"
}


:<<'EOF' 
Executes a 'exec' docker command
@param[1] container name
@param[2] a ref to a map giving option values (key=option name, value=option value).
          Supported values: 
		    'interactive' :(true/false) : if true, adds '--it' as command option,
		  	'privileged' (true/false) : if true, passes '--privileged' on as command option,
@param[n] command to execute inside container and arguments
EOF
dock__exec() {
	local containerName="$1"
	local -n containerOpt=$2
	
	local cmd=""
  	cmd="${__SUDO__}docker"
	cmd+=" exec"

	if [ "${containerOpt["interactive"]}" = true ] ; then
		cmd+=" -it"
	fi
	if [ "${containerOpt["privileged"]}" = true ] ; then
		cmd+=" --privileged"
	fi

	cmd+=" '${containerName}'"
	shift 2
	cmd+=" $@"
	_logf "DOCKER COMMAND: ${cmd}" 
  	eval "$cmd" 2>> "${__LOG_ERR_FILE__}" 
}

:<<'EOF' 
Copy a file or folder from a source located in a container or not, to a destination located in a container or not. 

If all container names are empty, an error is returned.

If src and dst container names are set, the file/older is copied from one container to the other using a temporary files

@param[1] source container name 
@param[2] source file path
@param[1] destination container name 
@param[3] destination file path
EOF
dock__copy() {
	local srcContainer="$1"
	local src="$2"
	local dstContainer="$3"
	local dst="$4"
	local cmd=""

	if Str__isEmpty "$srcContainer" && Str__isEmpty "$dstContainer" ; then

		_log_err "${FUNCNAME[0]} is used without any container name"
		return 1
	fi

	if ! Str__isEmpty "$srcContainer" && ! Str__isEmpty "$dstContainer" ; then
		# A temporary dir is used as buffer to store locally the source
		local tmpFileOrFolder=""
		File__createTempDir tmpFileOrFolder "$HOME" # Docker cannot copy to /tmp

		# First copy from src to tmp
		cmd="${__SUDO__}docker"
		cmd+=" cp"
		cmd+=" '${srcContainer}:${src}'"
		cmd+=" '${tmpFileOrFolder}/'"
		_logf cmd
		if eval "$cmd" >> "${__LOG_FILE__}" 2>> "${__LOG_ERR_FILE__}" ; then
			local srcBasename
			File__basename "$src" srcBasename
			cmd="${__SUDO__}docker"
			cmd+=" cp"
			cmd+=" '${tmpFileOrFolder}/${srcBasename}'"
			cmd+=" '${dstContainer}:${dst}'"
			_logf cmd
			eval "$cmd" >> "${__LOG_FILE__}" 2>> "${__LOG_ERR_FILE__}" 
		else
			_log_err "${FUNCNAME[0]}: failed to copy '$src' from '$srcContainer' to local filesystem"
			return 1		
		fi
	elif ! Str__isEmpty "$srcContainer" ; then
		cmd="${__SUDO__}docker"
		cmd+=" cp"
		cmd+=" '${srcContainer}:${src}'"
		cmd+=" '${dst}'"
		_logf cmd
		eval "$cmd" >> "${__LOG_FILE__}" 2>> "${__LOG_ERR_FILE__}" 
	else # if ! Str__isEmpty "$dstContainer" ; then
		cmd="${__SUDO__}docker"
		cmd+=" cp"
		cmd+=" '${src}'"
		cmd+=" '${dstContainer}:${dst}'"
		_logf cmd
		eval "$cmd" >> "${__LOG_FILE__}" 2>> "${__LOG_ERR_FILE__}" 
	fi
}

:<<'EOF' 
Stops a docker container
@param[1] container name
EOF
dock__stop() {
	local containerName="$1"
	local cmd=""
  	cmd="${__SUDO__}docker"
	cmd+=" stop"

	cmd+=" '${containerName}'"
	_logf "DOCKER COMMAND: ${cmd}" 
  	eval "$cmd"
}

:<<'EOF' 
Commits a new image from the passed container
@param[1] container name
@param[1] image name
EOF
dock__commit() {
	local containerName="$1"
	local containerImageName="$2"
	local cmd=""
  	cmd="${__SUDO__}docker"
	cmd+=" commit"

	cmd+=" '${containerName}'"
	cmd+=" '${containerImageName}'"
	_logf "DOCKER COMMAND: ${cmd}" 
  	eval "$cmd"
	
}


:<<'EOF' 
Starts or stop a container from a compose file
@param[1] in compose file name 
@param[2] in compose env file or empty string for using implicit default (.env)
@param[3] in compose command : up, down, run, exec, "exec /bin/bash"...
@param[4] in compose service to handle or empty for all
@param[5] in bool telling whether to detach
EOF
dock__compose() {
	local composeFile="$1"
	local envFile="$2"
	local composeCommand="$3" 
	local composeCommandOptions="$4"
	local composeService="$5"
	local ServiceCommand="$6"

	if ! File__fileExists "${composeFile}" ; then
		_log_err "File '${composeFile}' does not exist"
		return 1
	fi

	local cmd=""
  	cmd="${__SUDO__}docker"
	cmd+=" compose -f '${composeFile}'"

	if ! Str__isEmpty "$envFile" ; then
		cmd+=" --env-file '${envFile}'"
	fi

	cmd+=" ${composeCommand}"

	if ! Str__isEmpty "$composeCommandOptions" ; then
		cmd+=" ${composeCommandOptions}"
	fi

	cmd+=" --remove-orphans"

	if ! Str__isEmpty "$composeService" ; then
		cmd+=" ${composeService}"
	fi

	if ! Str__isEmpty "$ServiceCommand" ; then
		cmd+=" ${ServiceCommand}"
	fi	

	_logf "DOCKER COMMAND: ${cmd}" 
  	eval "$cmd"
}


:<<'EOF' 
This function does the same as dock__launch, except it builds all necessary arguments from a map already filled from a YAML file
and passes it on to dock__launch
@param[1] Ref to the map where are stored the YAML data as read by YAML__readAll. 
 		  When this latter is called via YAML__setFile, the global map YAML_data must be passed on as argument
@param[2] Parent node providing resp. image name and container name. 
		  The values are then read from the following child node:
		  - 'image' : name of the image from which to create the container
		  - 'container' : name of the container that is created

@param[3] Parent node providing the options. 
		  The values are then read from the following child node:
		  - 'privileged' (yes/no): name of the image from which to create the container
		  - 'net' : network (host means container gets access to LAN. See docker doc)


@param[3] a ref to a map giving option values (key=option name, value=option value).
          Supported values: 
		  	'privileged' (true/false) : if true, passes '--privileged' on as command option,
			'lan'  (true/false) : if true, passes '--net host' on as command option, meaning container has access to the local LAN
@param[4] a ref to a map giving environment variable value (key=var name, value=value)
@param[5] a ref to a map giving mount mappings (key=src folder, value=destination)
dock__launchFromConfig() {
	local containerImage="$1"
	local containerName="$2"
	local -n containerOpt=$3
	local -n containerEnv=$4
	local -n containerMounts=$5

}
EOF
