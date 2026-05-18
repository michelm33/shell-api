#!/bin/bash
###############################################################################
#
# Copyright (c) 2024 Michel Mehl. All rights reserved.
#
# -----------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
# -----------------------------------------------------------------------------
#
###############################################################################

__SHELL_API_YAML_DIR__=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

source "${__SHELL_API_YAML_DIR__}/shell-api-core.sh"

if _loaded "${BASH_SOURCE[0]}"  ; then
	return 0
fi

YAML__FILE=""
declare -A YAML_DATA
YAML__PREVFILE=""
YAML__YQ_NO_JQ_WRAP=true

echo "a: 1" | yq -o t -r ".[]" &>/dev/null
YAML__YQ_NO_JQ_WRAP=$?
#echo "YAML__YQ_NO_JQ_WRAP=$YAML__YQ_NO_JQ_WRAP"
#exit 0

:<<EOF
Sets the currently processed YAML file passed as 1st argument.
@param [1] YAML file
@param [2] OPTIONAL(false) bool telling whether to read all YAML file content and make it accessible via the global YAML_DATA map 
@returns 0
EOF

YAML__setFile() {
    YAML__PREVFILE="${YAML__FILE}"
    if [ ! -f "$1" ] ; then
        _log_err "$1 is not a YAML valid file"
        return 1;
    fi
    YAML__FILE="$(realpath -e "$1" 2>/dev/null)"

    if [ $# -ge 2 ] && $2 ; then
        _log_dbg "   YAML__setFile: READING GLOBAL MAP"
        YAML__readAll "${YAML__FILE}" YAML_DATA 
    fi
}

YAML__closeFile() {
    YAML__FILE="${YAML__PREVFILE}"
    YAML__PREVFILE=""
}

:<<EOF
Retrieves  whether the field path exists in the global YAML_DATA map holding all data
@param [1] in field path of form '.this.is.my.data.path'
@param [2] out the array of keys 
@returns true or false
EOF

YAML__getKeys()
{
    local -n 
    local k
    local val
    local -n allKeys=$2

    allKeys=()
    for k in "${!YAML_DATA[@]}" ; do
        if Str__startsWith "$k" "${1}." ; then
            local key="${k##*.}"
            #echo "key: '$key'"
            #if Str__contains "$key" "-" ; then
            #    key="'${key}'"
            #fi
            #echo "key: '$key'"
            allKeys+=("$key")
        fi
    done
}

:<<EOF
Checks whether the field path exists in the global YAML_DATA map holding all data
@param [1] in field path of form '.this.is.my.data.path'
@returns true or false
EOF

YAML__checkExists()
{
    [[ -v YAML_DATA["$1"] ]]
}

:<<EOF
Gets a YAML field from the global YAML_DATA map holding all data
@param [1] in field path of form '.this.is.my.data.path'
@param [2] out ref to variable where to store the data. 
@param [3] in OPTIONAL(false) tells whether field is optional. When so and field value
        is empty, then the input var is unchanged.
EOF

YAML__get()
{
    local __in_ypath="$1"
    local -n __out__storeVar=$2 
    local __storedValue=""
    local isArray=false
    #_log "YAML__get key: ${__in_ypath}"

    if Str__endsWith "${__in_ypath}" '\[\]' ; then
        isArray=true
        __in_ypath="${__in_ypath:0:-2}"
        #_log "IS ARRAY new key: ${__in_ypath}"
    fi

    __storedValue="${YAML_DATA["${__in_ypath}"]}"

    # Manage optionality. If empty return success anyway with empty string
    if [ $# -ge 3 ] && $3 && [ -z "${__storedValue}" ] ; then
        return 0
    fi
    
    if $isArray ; then
        if [ "${__storedValue}" = null ] ; then
            __out__storeVar=()
        else
            __out__storeVar=(${__storedValue})
        fi
:<<'EOF'
        __out__storeVar=()
	    local raw=(${__storedValue})
        local item
        for item in "${raw[@]}" ; do
            local val="${item//%20/ }"
            __out__storeVar+=("$val")
        done
EOF
    else
        #__out__storeVar="${__storedValue//%20/ }"
	    __out__storeVar="${__storedValue}"
    fi
}

YAML__isntVoid()
{
    local -n __in_val=$1
    if [ "$1" = null ] ; then return false; fi
    if [ -z "$1" ] ; then return false; fi
    return true;
}

YAML__unescape()
{
    local __in_val="$1"
    local -n __out__storeVar=$2
    __out__storeVar="${__in_val//%20/ }"
}

YAML__escape()
{
    local val="$1"
    local -n __out__storeVar=$2
    __out__storeVar="${val// /%20}"
}


YAML__get_bool()
{
    local -n __out__storeVar=$2
    local __initValue="${__out__storeVar}"
    YAML__get "$1" "${!__out__storeVar}"
    # Manage optionality. If empty return success anyway with empty string
    if [ $# -ge 3 ] && $3 && [ -z "${__out__storeVar}" ]; then
        __out__storeVar="${__initValue}" # preserve initial input value
        return 0
    fi
    local res
    YAML__assignBool "${__out__storeVar}" "$1" "${!__out__storeVar}"
    res=$?
    if [ $res -ne 0 ] ; then
        __out__storeVar="${__initValue}" # preserve initial input value
    fi
    return $res
}
YAML__get_int()
{
    local -n __out__storeVar=$2
    local __initValue="${__out__storeVar}"
    YAML__get "$1" "${!__out__storeVar}"
    # Manage optionality. If empty return success anyway with empty string
    if [ $# -ge 3 ] && $3 && [ -z "${__out__storeVar}" ]; then
        __out__storeVar="${__initValue}" # preserve initial input value
        return 0
    fi
    if ! Int__isInt "${__out__storeVar}" ; then
        _log_err "YAML value '${__out__storeVar}' given for '${!__out__storeVar}' is not an integer."
        return 1
    fi
}


:<<EOF
Get the currently processed YAML file as set with YAML__setFile.
@param [1] YAML file
@returns the return value of the yq command , i.e. 0 only on success.
EOF

YAML__getFilename() {
    echo $(basename "${YAML__FILE}")
    return 0
}

:<<EOF
Evaluates the rule passed as 1s argument from the currently set YAML file
@param [1] YAML filter rule
@returns the return value of the yq command , i.e. 0 only on success.
EOF

YAML__eval() {
    if [ $YAML__YQ_NO_JQ_WRAP -ne 0 ] ; then
        yq -r "$1" "${YAML__FILE}" #--yaml-output
    else
        yq -r "$1" "${YAML__FILE}"
    fi
}

:<<EOF
Reads an YAML field using YAML__eval and stores the values
in the passed named variable.
@param1 in data path
@param2 out variable where read values will be stored
@returns the return value of the yq command , i.e. 0 only on success.
EOF

YAML__read() {
    local -n _var="$2"

    local dataPath="$1"
    if [ ${dataPath:0:1} != "." ] ; then
        dataPath=".${dataPath}"
    fi

    #echo yq -r "${dataPath}" "${YAML__FILE}"

    if [ $YAML__YQ_NO_JQ_WRAP -ne 0 ] ; then
        if Str__endsWith "${dataPath}" '\[\]' ; then
            dataPath="${dataPath:0:-2}"
            #_log "IS ARRAY new key: ${__in_ypath}"
            _var=$(yq -r "${dataPath}" "${YAML__FILE}" | jq -r '.[]') #2>"${__LOG_ERR_FILE__}
        else
            _var=$(yq -r "${dataPath}" "${YAML__FILE}") #2>"${__LOG_ERR_FILE__}

            #| yq --yaml-output|grep -v '...'
        fi
        if Str__startsWith "$_var" '\{' && Str__endsWith "$_var" '\}' ; then
            _var="$(echo "$_var"|yq --yaml-output)"
        fi
    else        
        _var=$(yq -r "${dataPath}" "${YAML__FILE}") #2>"${__LOG_ERR_FILE__}"
    fi

    #echo " +++ YAML__read [${_var}]"
    #IFS='' read -r _var < <(yq -r "${dataPath}" "${YAML__FILE}") #2>"${__LOG_ERR_FILE__})
}

YAML__read_from_stdin() {
    if [ $YAML__YQ_NO_JQ_WRAP -ne 0 ] ; then
        yq -r "$1" # --yaml-output 
    else
        yq -r "$1"
    fi
}


:<<EOF
Same as YAML__read() except that when the field path does not exist, 
the output variable remains unchanged and not error is raised.
@param1 in field path
@param2 out variable where read values will be stored
@return 0 if field exists and value was read, 1 otherwise
EOF

YAML__read_optional() {
    local -n _var="$2"
    local dataPath="$1"
    if [ ${dataPath:0:1} != "." ] ; then
        dataPath=".${dataPath}"
    fi

    if YAML__exists "${dataPath}" ; then
        _var=$(yq -r "${dataPath}" "${YAML__FILE}")
        return 0
    else
        return 1
    fi
}

YAML__read_bool() {
    local -n _var="$2"
    local yevalres
    YAML__read "$1" yevalres
    if [ $? -eq 0 ] ; then
        YAML__assignBool "$yevalres" "$1" "${!_var}"
        return $?
    else
        return 1
    fi
}

YAML__assignBool()
{
    local __in_yevalres="$1" # raw bool val
    local __in_boolvar="$2" # var name/yaml path
    local -n __in_storeVar=$3
    Str__toLower yevalres
    if [ "${__in_yevalres}" == "yes" ] ; then
        __in_storeVar=true
    elif [ "${__in_yevalres}" == "no" ] ; then
        __in_storeVar=false
    elif [ "${__in_yevalres}" != "~" ] ; then
        # ~ is the neutral value, do not change current value
        _log_err "YAML value '$1' given for '${__in_boolvar}' is not a boolean. It must be 'yes' or 'no'."
        return 1
    fi
}

YAML__read_int() {
    local -n _var="$2"
    local val
    YAML__read "$1" val
    if [ $? -eq 0 ] ; then
        if ! Int__isInt "$val" ; then
            _log_err "YAML value for $1 is not an integer."
            return 1
        fi
        _var="$val"
        return 0
    else
        return 1
    fi
}

:<<EOF 
Writes in-place an YAML field
@param1 in data path
@param2 in value to assign
@returns the return value of the yq command , i.e. 0 only on success.
EOF

YAML__write() {
    local dataPath="$1"
    local newValue="$2"
    local setCommand="${dataPath} |= \"${newValue}\""

    if [ $YAML__YQ_NO_JQ_WRAP -ne 0 ] ; then
        #echo yq --yaml-output -i "${setCommand}" "${YAML__FILE}" 
        yq --yaml-output -i "${setCommand}" "${YAML__FILE}" #2>"${__LOG_ERR_FILE__}"
    else
        yq -i e "${setCommand}" "${YAML__FILE}" #2>"${__LOG_ERR_FILE__}"
    fi
}

:<<EOF
Writes in-place an YAML array
@param1 in data path
@param2 in a space-separated values
@returns the return value of the yq command , i.e. 0 only on success.
EOF

YAML__writeArray() {
    local dataPath="$1"
    shift
    local newArray=($@)
    #_log "YAML__writeArray $# args : '$dataPath' '${newArray[@]}' "
    local builtAssignedArrayVal=""
    if [ ${#newArray[@]} -eq 0 ] ; then
        builtAssignedArrayVal="[ "
    fi
    #_log "YAML__writeArray : newArray: ${#newArray[@]} , '${newArray[@]}'"

    local __val
    for __val in "${newArray[@]}"
    do
        if [ -z "${builtAssignedArrayVal}" ] ; then
            builtAssignedArrayVal="[ \"${__val}\""
        else
            builtAssignedArrayVal="${builtAssignedArrayVal} , \"${__val}\""
        fi
    done

    builtAssignedArrayVal="${builtAssignedArrayVal} ]"
    local setCommand="${dataPath} |= ${builtAssignedArrayVal}"

    #_log "YAML__writeArray : command: '$setCommand'"
    if [ $YAML__YQ_NO_JQ_WRAP -ne 0 ] ; then
        #echo yq --yaml-output -i "${setCommand}" 
        yq --yaml-output -i "${setCommand}" "${YAML__FILE}"    
    else
        yq -i e "${setCommand}" "${YAML__FILE}" #2>"${__LOG_ERR_FILE__}"
    fi
}


:<<EOF
Tells whether the YAML filter rule , resp. YAML field,
is not 'null' in the currently set YAML file
@param [1] YAML filter rule
@return 0 when so, 1 otherwise
EOF

YAML__exists() {
    local exists=$(yq "$1" "${YAML__FILE}")
    if [ "$exists" == "null" ] ; then
        return 1
    else
        return 0
    fi
}

:<<EOF
If YAML__exists is successfully, returns the keys of the matching YAML field.
@param [1] YAML filter rule
@return If rule result is not null, returns status of 'yq', 1 otherwise
EOF

YAML__keys() {
    local dataPath="$1"
    if [ ${dataPath:0:1} != "." ] ; then
        dataPath=".${dataPath}"
    fi
    #if YAML__exists "$1" ; then
    if [ $YAML__YQ_NO_JQ_WRAP -ne 0 ] ; then
        #echo "RETRIEVING KEYS ${dataPath}" >&2
        yq -r "${dataPath} | keys" "${YAML__FILE}" | jq -r ".[]"
    else
        yq -o t -r "${dataPath} | keys" "${YAML__FILE}"
    fi
    #else
    #    yq -o t -r "$1 | keys" 
        #log_warn "no such field $1"
        #return 1
    #fi
}

YAML__nbKeys_from_stdin()
{
    if [ $YAML__YQ_NO_JQ_WRAP -ne 0 ] ; then
        yq "$1 | keys" | jq -r ".[]" | wc -l 
    else
        yq "$1 | keys" | wc -l
    fi
}

YAML__nbKeys()
{
    #if YAML__exists "$1" ; then
    if [ $YAML__YQ_NO_JQ_WRAP -ne 0 ] ; then
        yq "$1 | keys" "${YAML__FILE}" | jq -r ".[]"  |  wc -l
    else
        yq "$1 | keys" "${YAML__FILE}" | wc -l
    fi
    #else
    #    yq "$1 | keys"  | wc -l
        #log_warn "no such field $1"
        #return 1
    #fi
}

YAML__keys_from_stdin() {
    if [ $YAML__YQ_NO_JQ_WRAP -ne 0 ] ; then
       yq -r "$1 | keys" | jq -r ".[]"
    else
       yq -o t -r "$1 | keys" 
    fi
}


YAML__writeAll() 
{
    if ! Args__checkCount ${FUNCNAME[0]} 2 "$#" "usage: <file> <map>"; then return 1; fi

    local -n storeMap=$2
    local f="$1"
    
    echo > "$f"
    local k
    for k in "${!storeMap[@]}" ; do
        echo "$k: ${storeMap[$k]}" >> "$f"
    done
    echo >> "$f"
}

YAML__normalize() 
{
    if ! Args__checkCount ${FUNCNAME[0]} 1 "$#" "usage: <map>"; then return 1; fi

    local -n storeMap=$1
    local key
    for key in "${!storeMap[@]}" ; do
        storeMap["${key:1}"]="${storeMap["$key"]}"
        storeMap["$key"]=""
        unset storeMap["$key"]
    done
}

:<<'EOF'
TODO:
[x] a single-line string written on several line
    e.g. 
    field: 
       this is one 
       sentence line written on multiple lines
[x] special chars not accepted as keys e.g. starting hyphen? or punctuation? to check!
NOTE: keys with spaces are accepted
EOF

YAML__readAll() 
{
    if ! Args__checkCount ${FUNCNAME[0]} 2 "$#" "usage: <file> <map> "; then return 1; fi

    if [ ! -e "${1}" ] ; then
        _log_err "${FUNCNAME[0]}: YAML file '${1}' does not exist."
        return 1
    fi
    if [ ! -f "${1}" ] ; then
        _log_err "${FUNCNAME[0]}: YAML file '${1}' is not a valid file."
        return 1
    fi
    local -n storeMap=$2

    # Clear existing stored values
    local k
    for k in "${!storeMap[@]}" ; do
        storeMap[$k]=""
    done

    local lineCount=0
    local _line=""
    local c=0
    local yline=""
    local ypath=""
    local ypath_indent=0
    local line_indent=0
    local yk
    local ykRaw
    local yv
    local yvRaw
    local first=true
    local arrayValuesComing=false
    local multilineValComing=false
    local multilineIndent=0 # Gives the relative indent to the parent declaring the multiline
    local multilineValComingWasRead=false
    declare -A indentYPathMap

    _log_dbg "reading all YAML file '${1}'"

    while IFS= read -r _line
    do
        if [ $lineCount -eq 0 ] && [ "$_line" = "---" ] ; then continue ; fi
:<<'EOF'
        # Ignore empty lines
        Str__trim "$_line" line
        if [ -z "$_line" ] ; then
            continue
        fi

        if [ "${_line:0:1}" = "#" ] ; then
            return 0
        fi
EOF
        lineCount=$(($lineCount + 1))

        Str__skipWs "$_line" yline line_indent        
        if [ ${#yline} -eq 0 ] || [[ "${yline:0:1}" =~ [[:space:]] ]] || [ "${yline:0:1}" = "#" ]; then continue; fi
        

        #echo "'$_line': '$yline' $c"
        # If the indent is less or the same, this is a new field 
        # Save the 

        if [ "${yline:0:2}" = "- " ]  ; then
            ykRaw="${yline}"
            yvRaw="${yline}"
        else
            ykRaw="${yline%%:*}"
            yvRaw="${yline#*:}"
        fi
        ykRaw="${ykRaw//%3A/:}"
        yvRaw="${yvRaw//%3A/:}"

        # trim any leading and trailing space, since it reads a word sequence
        read -r yk <<< "${ykRaw}"
        read -r yv <<< "${yvRaw}"

        # Trim quote chars also from the key
        #echo "KEY  '${yk}'"
        if YAML__trimQuotes "${yk}" "${yk}" yk '"' ; then        
            YAML__trimQuotes "${yk}" "${yk}" yk "'" 
        fi

        if [ "$yv" = "|" ] || [ "$yv" = "|+" ] || [ "$yv" = "|+" ] || [ "$yv" = ">" ]  || [ "$yv" = ">+" ] || [ "$yv" = ">-" ]; then
            multilineValComing=true
            multilineValComingWasRead=true
        else
            multilineValComingWasRead=false
        fi
    
        # If multiline is ongoing, take the raw whole line as value to append
        if $multilineValComing ; then 
            if ! $multilineValComingWasRead ; then
                yv="$_line"                
                yv="${yv:${ypath_indent}}" # Suppress the same amount of whitespace as the property was indented.
            else
                # else , lines will come next lines
                yv=""
            fi
        elif ! $arrayValuesComing ; then
            # else if not being reading line-by-line array values
            YAML__readAll_decodeArrayValue yv ${lineCount} "${_line}"
        fi 

        #_log_vars yline line_indent ykRaw yvRaw ypath
        #for iyp in "${!indentYPathMap[@]}" ; do 
        #    _log "for indent $iyp: ${indentYPathMap[$iyp]}"
        #done
        #_log "YPATH: '$ypath', yv:${yv}, yk:${yk}, ypath_indent:${ypath_indent} , indentYPathMap : '${indentYPathMap[${line_indent}]}'"

        if [ $line_indent -le ${ypath_indent} ] || $first  ; then
            if [ "$ykRaw" = "$yline" ] ; then 
                _log_warn "${lineCount}: unexpected line '$_line' coming after ${ypath}. Ignored."
                continue
            fi            
            #prevypath="${ypath}"
            # Reset any multiline flag set
            if ! $multilineValComingWasRead ; then 
                if $multilineValComing ; then
                    multilineValComing=false
                    read -r yv <<< "${yvRaw}"  
                    YAML__readAll_decodeArrayValue yv ${lineCount} "${_line}"
                fi
            fi

            arrayValuesComing=false
            
            if [ ${line_indent} -eq 0 ] || $first ; then
                # ROOT PROP
                first=false
                #storeMap["$yk"]="$yv"   
                YAML__readAll_storeValue "${!storeMap}" "$yk" "$yv" 
                if [ ! -z "$yv" ] ; then
                    # Store root property
                    ypath=""        # Restart from 0 searching for new prop
                else
                    ypath="${yk}"   # This is now a new root prop, value to come (simple, array or composed)
                fi
                #_log "CASE 1: ypath:$ypath, line_indent:$line_indent"
                ypath_indent=${line_indent}
                indentYPathMap[${line_indent}]="${ypath}"

            elif [ ${line_indent} -eq ${ypath_indent} ] ; then
                #_log "=======>  line_indent(${line_indent}) == ypath_indent EQUAL for $yk "

                # PROP OF SAME LEVEL.
                ypathNew="${ypath%\%46*}"
                if [ "$ypathNew" = "$ypath" ] ; then
                    ypath="${yk}" 
                else
                    ypath="${ypathNew}%46${yk}" 
                fi

                #storeMap["${ypath}"]="$yv"   
                YAML__readAll_storeValue "${!storeMap}" "$ypath" "$yv" 

                # NOTE: ypath_indent is unchanged
                indentYPathMap[${line_indent}]="${ypath}"
            else # line_indent < ypath_indent
                #_log "=======>  line_indent(${line_indent}) < ypath_indent(${ypath_indent}) for $yk "
                # Clear map at ypath_indent
                indentYPathMap[${ypath_indent}]=""

                ypath="${indentYPathMap[${line_indent}]}"
                local search_line_indent="${line_indent}"
                # Search for a sibling and get its parent
                while [ -z "${ypath}" ] && [ ${search_line_indent} -gt 0 ]; do
                    search_line_indent=$((${search_line_indent} - 1 ))
                    ypath="${indentYPathMap[${search_line_indent}]}"
                done
                #_log "FOUND NODE OF SAME INDENT: '$ypath' at search_line_indent:${search_line_indent} "

                if [ ${search_line_indent} -eq 0 ] ; then
                    #storeMap["$yk"]="$yv"   
                    YAML__readAll_storeValue "${!storeMap}" "$yk" "$yv" 

                    if [ -z "$yv" ] ; then
                        ypath="${yk}"   # This is now the new root prop, value to come (simple, array or composed)
                    fi
                else
                    ypathNew="${ypath%\%46*}"
                    if [ "$ypathNew" = "$ypath" ] ; then
                        ypath="${yk}" 
                    else
                        ypath="${ypathNew}%46${yk}" 
                    fi

                    # ${ypath} is necessarily not numm
                    #storeMap["${ypath}"]="$yv"   
                    YAML__readAll_storeValue "${!storeMap}" "$ypath" "$yv" 
                fi

                ypath_indent=${search_line_indent}
                indentYPathMap[${search_line_indent}]="${ypath}"
            fi

        else
            # indent increase. This can be a
            # - a value if none was supplied before not containing ':'
            # - a string value that may contain ':' but the | must have been provided before 
            # - arrays either inline or line by line starting with -
            # - another prop
:<<'EOF'
            if [ ! -z "${storeMap["${ypath}"]}" ] ; then
                _log_warn "${lineCount}: unexpected line '$yline' coming after ${ypath}. Ignored."
                continue
            fi
EOF
            #_log "indent increase '$yline' for $ypath: this is not a prop assign, but a plain value. multilineValComing:${multilineValComing}, multilineValComingWasRead: ${multilineValComingWasRead}, arrayValuesComing:${arrayValuesComing}"
            if [ "$ykRaw" = "$yline" ] || $arrayValuesComing || ($multilineValComing && ! $multilineValComingWasRead); then 
                #_log "'$yline' for $ypath: this is not a prop assign, but a plain value"

                local curStoreValue=""
                YAML__readAll_getStoreValue "${!storeMap}"  "${ypath}" curStoreValue
                #_log "curStoreValue: '$curStoreValue'"
                # this is not a prop assign, but a plain value
                if [ -z "${ypath}" ] ; then
                    _log_warn "${lineCount}: unexpected line '$_line'. There is no valid context parent property. Ignored."
                    continue
                elif [ ! -z "${curStoreValue}" ] ; then
                #elif [ ! -z "${storeMap["${ypath}"]}" ] ; then
                    if $multilineValComing ; then
                        yv="${yv:${multilineIndent}}"
                        #storeMap["${ypath}"]="${storeMap["${ypath}"]}
#$yv"
                        YAML__readAll_storeRawValue "${!storeMap}" "$ypath" "${curStoreValue}
$yv"

                    elif $arrayValuesComing  ; then
                        if [ "${yv:0:2}" = "- " ] ; then                    
                            yv="${yv:2}"
                            if YAML__readAll_decodeQuote yv ${lineCount} "${_line}" ; then
                                yv="${yv// /%20}"
                            else 
                                # It may be an inline array inside an array item!
                                YAML__readAll_decodeArrayValue yv ${lineCount} "${_line}"
                            fi
                            #storeMap["${ypath}"]="${storeMap["${ypath}"]} $yv"
                            YAML__readAll_storeValue "${!storeMap}" "$ypath" "${curStoreValue} $yv"
                        else
                            _log_warn "${lineCount}: unexpected line '$_line'. Expected another array value  (missing '-'?) or another property (missing ':'?). Ignored."
                        fi
                    else
                        _log_warn "${lineCount}: unexpected line '$_line'. Parent property has already been assigned the value ${storeMap["${ypath}"]}. Ignored."
                        continue
                    fi
                else
                    if [ "${yv:0:2}" = "- " ] ; then
                        #_log "====> '$yline' for $ypath: start with array values"
                        arrayValuesComing=true
                        yv="${yv:2}"
                        if YAML__readAll_decodeQuote yv ${lineCount} "${_line}" ; then
                            yv="${yv// /%20}"
                        else
                            # It may be an inline array inside an array item!
                            YAML__readAll_decodeArrayValue yv ${lineCount} "${_line}"
                        fi
                    fi

                    # If multiple lines active, this is the first line
                    #  note the number of indent to remove relatively to the first
                    if $multilineValComing ; then
                        multilineIndent=$(( ${line_indent} - ${ypath_indent} ))
                        #echo "=======> multilineIndent: $multilineIndent"
                        yv="${yv:${multilineIndent}}"
                    fi

                    #storeMap["${ypath}"]="$yv"
                    YAML__readAll_storeValue "${!storeMap}" "$ypath" "$yv"
                fi
            else
                if [ -z "${ypath}" ] ; then
                    _log_warn "${lineCount}: unexpected line '$_line'. There is no valid context parent property. Ignored."
                    continue
                else
                    ypath="${ypath}%46${yk}" 
                    ypath_indent=${line_indent}
                    indentYPathMap[${line_indent}]="${ypath}"                    
                    #storeMap["${ypath}"]="$yv"
                    YAML__readAll_storeValue "${!storeMap}" "$ypath" "$yv"
                fi
            fi
        fi
        
        #if [ -z "$yline"] ; then continue ; fi

    done < "$1" 
}


YAML__readAll_getStoreValue()
{
    local -n __in_storeMap=$1
    local __in_k="$2"
    local -n __out_value=$3
    local actualKey="${__in_k//%46/.}"
    __out_value="${__in_storeMap[".${actualKey}"]}"
}

YAML__trimQuotes()
{
    local referenceKey="$1"
    local referenceValue="$2"
    local -n currentValue=$3
    local quoteChar="$4"
    
    local initialLen=${#currentValue}
    local len=${initialLen}
    #_log "YAML__trimQuotes: currentValue: '${currentValue}', len: ${len}, referenceValue: '${referenceValue}'"
    if [ "${currentValue:0:1}" = "$quoteChar" ] ; then                    
        local len=${initialLen}
        if [ $len -lt 2 ] ; then
            # This may indicate the # was a relevant char in a quote and not a comment
            currentValue="${referenceValue}"
            len=${#currentValue}
        fi

        if [ "${currentValue:$(($len-1))}" != "$quoteChar"  ] ; then
            #actualVal="??? bad value: ${actualVal} ???"
            _log_warn "Expected closing quote char '$quoteChar' for value '$currentValue'."
        else
            if [ $len -lt 2 ] ; then
                _log_err "for '$referenceKey' original value '$referenceValue': Expected closing quote char '$quoteChar' for value '$currentValue'."
            else
                currentValue="${currentValue:1:$(($len-2))}"
            fi
        fi

        len=${#currentValue}
    fi
    #_log "[END] YAML__trimQuotes: currentValue: '${currentValue}', len: ${len}"

    [ $initialLen -eq $len ]
}

YAML__readAll_storeRawValue()
{
    local -n __in_storeMap=$1
    local __in_k="$2"
    local __in_v="$3"
    local actualKey="${__in_k//%46/.}"
    local actualVal="${__in_v}"
    __in_storeMap[".${actualKey}"]="${actualVal}"
}

YAML__readAll_storeValue()
{
    local -n __in_storeMap=$1
    local __in_k="$2"
    local __in_v="$3"
    local actualKey="${__in_k//%46/.}"
    local actualVal="${__in_v}"

    # Remove any trailing comment
    # if # is inside quote? may not work ,
    # but in the dbl quote test below would then fail tool
    # Specific case
    # PROVEN CASE : when # in located on the last line of a multiline string
    actualVal="${actualVal%#*}" 
    Str__trimEnd "$actualVal" actualVal

    # Trim quote chars from the value
    if YAML__trimQuotes "${actualKey}" "${__in_v}" actualVal '"' ; then        
        YAML__trimQuotes "${actualKey}" "${__in_v}" actualVal "'" 
    fi
    
    #echo "KEY: '$actualKey'"
    #echo "VAL: '$actualVal' __in_storeMap:'${!__in_storeMap}'"
    __in_storeMap[".${actualKey}"]="${actualVal}"
    #cmd="__in_storeMap[\".${actualKey}\"]=\"${actualVal}\""
    #eval "$cmd"
}

YAML__readAll_decodeQuote()
{
    local -n __in_val=$1
    local __in_lc="$2"
    local __in_line="$3"

    read -r __in_val <<< "${__in_val}" # Trim both ends
    len=${#__in_val}
    if [ "${__in_val:0:1}" = "\"" ] ; then                    
        if [ "${__in_val:$(($len-1))}" != "\"" ] ; then
            __in_val="??? bad array value: ${__in_val} ???"
            _log_warn "${__in_lc}: unexpected line '$__in_line'. Malformed quote. Expected closing double quote for value '$__in_val'."
            return 1                
        fi
        __in_val="${__in_val:1:$(($len-2))}"
        return 0
    elif [ "${__in_val:0:1}" = "'" ] ; then                    
        if [ "${__in_val:$(($len-1))}" != "'" ] ; then
            __in_val="??? bad array value: ${__in_val} ???"
            _log_warn "${__in_lc}: unexpected line '$__in_line'. Malformed quote. Expected closing double quote for value '$__in_val'."
            return 1                
        fi
        __in_val="${__in_val:1:$(($len-2))}"
        return 0
    else
        return 1 # return 1 to signal it was not a quote
    fi
}

YAML__readAll_decodeArrayValue()
{
    local -n __in_yv=$1
    local __in_lc="$2"
    local __in_line="$3"
    local len=${#__in_yv}
    if [ "${__in_yv:0:1}" = "[" ] ; then

        local valTillCloseBracket="${__in_yv%%]*}"  # Stop at the first encountered ]
        #_log_vars valTillCloseBracket
        if [ "$valTillCloseBracket" =  "${__in_yv}" ] ; then
        #if [ "${__in_yv:$(($len-1))}" != "]" ] ; then
            __in_yv="??? bad array value: ${__in_yv} ???"
            _log_warn "${__in_lc}: unexpected line '$__in_line'. Malformed array value. Expected closing ']'."
            return 1
        else
            local arrSize=${#valTillCloseBracket}
            local remainingString="${__in_yv:$arrSize}"
            #_log_vars valTillCloseBracket arrSize remainingString
            # Get the string without the still contained close bracket (the most left one)
            remainingString="${remainingString#*]}" 
            read -r remainingString <<< "$remainingString" # to trim
            if [ ! -z "${remainingString:0:1}" ] && [ "${remainingString:0:1}" != "#" ] ; then
                __in_yv="??? bad array value: ${__in_yv} ???"
                _log_warn "${__in_lc}: unexpected line '$__in_line'. Bad string following array end bracket."
                return 1   
            fi

            __in_yv="${valTillCloseBracket}]"
            len=${#__in_yv}
        fi     

        local str=${__in_yv:1:$(($len-2))}
        __in_yv=""
        #read str <<< "$str" # This enables to trim whitespace at both ends of the string
        #echo "STR: '$str', len:$len"
        local arrayValues=()
        readarray -t -d',' arrayValues <<< ${str}
        local i=0
        while [ $i -lt ${#arrayValues[@]} ]
        do
            local av=${arrayValues[$i]}
            YAML__readAll_decodeQuote av ${lineCount} "${_line}"
            # add value
            av="${av// /%20}"
            if [ -z "${__in_yv}" ] ; then
                __in_yv="$av"
            else
                __in_yv="${__in_yv} $av"
            fi

            i=$(($i + 1))
        done
    fi
}

YAML__dumpAll()
{
    local k
    if [ $# -eq 0 ] ; then
        for k in "${!YAML_DATA[@]}" ; do
            echo "$k: ${YAML_DATA[$k]}"
        done
    else
        local -n storeMap=$1
        for k in "${!storeMap[@]}" ; do
            echo "$k: ${storeMap[$k]}"
        done
    fi
}

:<<'EOF'
This function returns the keys from the YAML data store.
It only works if there's one level of root nodes, otherwise
it would return all nodes. This can be solve by checking the dots,
but considering the node names might themselves contain dots.
EOF
YAML__getKeysFromStore()
{
    local -n __inStoreMap=$1
    local -n __outKeys=$2
    local k
    __outKeys=()
    for k in "${!__inStoreMap[@]}" ; do
        local value="${__inStoreMap[$k]}"
        #_log "'${k}': '${value}'"
        if [ -z "$value" ] ; then
            Str__trimStart "$k" k "."
            __outKeys+=("$k")
        fi
    done
}

:<<'EOF'

                    # NO:
                    # Remove this node from current path since it was assigned a value
                    #ypath="${ypath##*.}"
                    # NO:
                    # This is now a new node prop, value to come (simple, array or in turn composed of other prop(s)) 
                    # Replace last item in path with the new key
                    #ypath="${ypath##*.}"
                    #ypath="${ypath}.${yk}" 
EOF