#!/bin/bash
MYDIRNAME="${BASH_SOURCE[0]%/*}"
MYDIR="$(readlink -f "${MYDIRNAME}")"

cd "${MYDIR}/.." 

make web

pushd ~/siteweb/developertoolsforlinux &>/dev/null && make gensiten && popd &>/dev/null || popd &>/dev/null
