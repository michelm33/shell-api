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
  	eval "$cmd"
}

:<<'EOF' 
Copy a file into the docker container
@param[1] container name
@param[2] source file path
@param[3] destination file path
EOF
dock__copy() {
	local containerName="$1"
	local src="$2"
	local dst="$3"
	local cmd=""
  	cmd="${__SUDO__}docker"
	cmd+=" cp"
	cmd+=" '${src}'"
	cmd+=" '${containerName}:${dst}'"
	_log_vars cmd >&2 
  	eval "$cmd"
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
