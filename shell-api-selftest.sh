#!/bin/bash
###############################################################################
#
# Copyright (c) 2024-2025 Michel Mehl. All rights reserved.
#
# -----------------------------------------------------------------------------
#
# Report bugs to michel.mehl@slashetc.fr
#
# -----------------------------------------------------------------------------
#
###############################################################################
trap _cleanup EXIT SIGHUP SIGINT SIGTERM SIGQUIT SIGABRT

__SHELL_API_SELFTEST_DIR__=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

source "${__SHELL_API_SELFTEST_DIR__}/shell-api-core.sh"
source "${__SHELL_API_SELFTEST_DIR__}/shell-api-yaml.sh"

if _loaded "${BASH_SOURCE[0]}"  ; then
	return 0
fi




Test__resultAll=0

###############################################################################
# UNFORMAL QUICKTESTS TO BE PUT IN ORDER

timerid=0
elapsed=0
Date__startTimer timerid 
sleep 5
Date__elapsedSecondsTimer $timerid elapsed
echo "${elapsed} seconds elapsed"
sleep 3
Date__elapsedSecondsTimer $timerid elapsed
echo "${elapsed} seconds elapsed"
Date__elapsedMinutesTimer $timerid elapsed
echo "${elapsed} minutes elapsed"
exit 0



testYamlPerfReadAll() {
    declare -A myYAMLDataMap
    for i in {1..100};do
        YAML__readAll "/home/michel/website2/conf/bookmake.yml" myYAMLDataMap 
        YAML__dumpAll
    done
}
testYamlOneFile() {
    echo
    echo "---"
    echo
    if [ $# -eq 2 ] ; then
        echo "test file: $2"
        testfile="$2"
    else
        testfile="/tmp/test.yml"
        echo "$1" >  "$testfile"
    fi
    declare -A myYAMLDataMap
    YAML__readAll "$testfile" myYAMLDataMap 
    YAML__dumpAll myYAMLDataMap
}

#testYamlOneFile "" "/home/michel/website2/conf/bookmake.yml" ; exit 0


testStr="$(cat <<'EOF' 
titles:
 - [ "1", "Milan", ~ ]
 - [ "2", "Rome", "2023-04-23{nbsp}00:00:00" ]
 - [ "3", "Pompéi", "2023-04-29{nbsp}00:00:00" ]


EOF
)"
testYamlOneFile "$testStr"  

#exit 0


testStr="$(cat <<'EOF' 
  include:
    start-date: ~
    end-date: ~
    explicit-files:
      "mountpilot_sshot_list_1.png" :
        chapter: "Examples of list commands for list 1"
        title: "Default List (everything but loop devices)"
      "mountpilot_sshot_list_2.png" :
        chapter: "Examples of list commands for list 2"
        title: "List all except loop devices (default behavior)"
EOF
)"
testYamlOneFile "$testStr"  
#exit 0

testYArray1='[ 1,2,3,4]# comment with an array [ word, int ]'
echo "result for $testYArray1"
YAML__readAll_decodeArrayValue testYArray1 1 " bidon" 
echo "'$testYArray1'"

testYArray1='[ 1,2,3,4]#comment'
echo "result for $testYArray1"
YAML__readAll_decodeArrayValue testYArray1 1 " bidon" 
echo "'$testYArray1'"

testYArray1='[ 1,2,3,4]  #comment'
echo "result for $testYArray1"
YAML__readAll_decodeArrayValue testYArray1 1 " bidon" 
echo "'$testYArray1'"

testYArray1='[ 1,2,3,4]'
echo "result for $testYArray1"
YAML__readAll_decodeArrayValue testYArray1 1 " bidon" 
echo "'$testYArray1'"

testYArray2='[ "s1", "s2", "s3" ]'
echo "result for $testYArray2"
YAML__readAll_decodeArrayValue testYArray2 1 " bidon" 
echo "'$testYArray2'"

testYArray2='[ "value with space", "s2", " here also spaces at both ends " ]'
echo "result for $testYArray2"
YAML__readAll_decodeArrayValue testYArray2 1 " bidon" 
echo "'$testYArray2'"


testYArray3='[ "s1", "s2", "s3"'
echo "result for $testYArray3"
YAML__readAll_decodeArrayValue testYArray3 1 " bidon" 
echo "'$testYArray3'"

testYArray4='[ "s1", "s2, "s3" ]'
echo "result for $testYArray4"
YAML__readAll_decodeArrayValue testYArray4 1 " bidon" 
echo "'$testYArray4'"

#exit 0




testStr="$(cat <<'EOF' 
f0: 
 - f0_1
 - f0_2

field1: - f1_1
 - f1_2

f2: 
 - f2_1 with space
 - f2_2 with space too

f3:
  f4:
    - v1
  -v2:12

f4: [ 1,2,3,4]
f5:
  [ "s1", "s2", "s3" ]

# Values with quotes
f6: 
    -    "file1 f6"  
    - "file2 f6"
    - "file3 f6"
    - "file4 f6"

titles:
 - [ "1", "Milan", ~ ]
 - [ "2", "Rome", "2023-04-23{nbsp}00:00:00" ]
 - [ "3", "Pompéi", "2023-04-29{nbsp}00:00:00" ]


EOF
)"
testYamlOneFile "$testStr"  

exit 0


testStr="$(cat <<'EOF' 
property0:
    property1 : | 
     1st line of property1
     2nd line of property1
         third line with more indent
     prop2: caramel - a crazy one

p0:
    p1 : | 
        1st line of p1
           2nd line of p1
              third line with more indent
        4th line

property2: |
 1st line of property2
 2nd line of property2


property3:
  joe
  tata
EOF
)"
testYamlOneFile "$testStr"  

#exit 0

testStr="$(cat <<'EOF' 
property1 : | 
   this is a simple multiline value                
   second line
EOF
)"
testYamlOneFile "$testStr"  

#exit 0


testStr="$(cat <<'EOF' 
property1 :
  subprop1_1: 
      value is below
  subprop1_2:
      subprop1_2_1: 
                1_2_1 value below too
      subprop1_2_2: 1_2_2 value on the same level
                
EOF
)"
testYamlOneFile "$testStr" 

#exit 0


testStr="$(cat <<'EOF' 
property1 :
  subprop1_1: 
      subprop1_1_1: zizou
   subprop1_2:
      subprop1_2_1: 
prop2: 
    subprop2_1:
        subprop2_1_1: tata
        subprop2_1_2: toto
EOF
)"
testYamlOneFile "$testStr" 

exit 0

testStr="$(cat <<'EOF' 
property1 :
    subprop1_1: 
        subprop1_1_1: zizou
    subprop1_2:
        subprop1_2_1: 
prop2: 
    subprop2_1:
        subprop2_1_1: tata
        subprop2_1_2: toto
prop3: 
    subprop3_1:
prop4: 
    subprop4_1: joe

property2 : val2
property3 : val3
property4 : 
    subprop4_1: subval4_1
    subprop4_2: subval4_2
    subprop4_3: subval4_3
EOF
)"
testYamlOneFile "$testStr" 

exit 0


testStr="$(cat <<'EOF' 
property1 :
    subprop1_1: 
        subprop1_1_1: 
    subprop1_2:
        subprop1_2_1: 
        subprop1_2_2: 
    subprop1_3:
        subprop1_3_1: 
        subprop1_3_2: toto
property2 : val2
property3 : val3
property4 : 
    subprop4_1: subval4_1
    subprop4_2: subval4_2
    subprop4_3: subval4_3
EOF
)"
testYamlOneFile "$testStr"

exit 0

testStr="$(cat <<'EOF' 
    property1 :
        subprop1_1: 
            subprop1_1_1: 
            subprop1_1_2: 
            subprop1_1_3: 
    property2 : val2
    property3 : val3
    property4 : val4 
        subprop4_1: subval4_1
        subprop4_2: subval4_2
        subprop4_3: subval4_3
EOF
)"
testYamlOneFile "$testStr"

#exit 0
testStr="$(cat <<'EOF' 
    property1 :
        subprop1_1: subval1_1
    property2 : val2
    property3 : val3
    property4 : val4 
        subprop4_1: subval4_1
EOF
)"
testYamlOneFile "$testStr"
#exit 0

testStr="$(cat <<'EOF' 
property1 : 
    subprop1_1: subval1_1
property2 : val2
property3 : val3
property4 :
    subprop4_1: subval4_1
EOF
)"
testYamlOneFile "$testStr"

testStr="$(cat <<'EOF' 
    property1 : val1
    property2 : val2
    property3 : val3
    property4 : val4 
EOF
)"
testYamlOneFile "$testStr"

exit 0


commonTailStr=""
Str__nbCommonEndString "Mounting a block DEvice"  "Example of mounting of a block device" commonTailStr
_log_vars commonTailStr
exit 0
adbStr=""
Adb__getVersion adbStr
_log_vars adbStr
Adb__getSDKVersion adbStr
_log_vars adbStr
Adb__getDeviceName adbStr
_log_vars adbStr
Adb__listDevices adbStr
echo "List of devices "${adbStr[@]}""
exit 0
_log_high "Testing install alternatives exfat-utils|exfatlabel"
Pkg__install "exfatlabel@exfat-utils|exfatlabel" "" apt
_log_high "Testing install alternatives exfatlabel|exfat-utils"
Pkg__install "exfatlabel@exfatlabel|exfat-utils" "" apt
exit 0
# Env__distrover()
distro=""
time Env__distrover 1 distro
time echo "$distro"
time Env__distrover 2  distro
time echo "$distro"
time Env__distrover 3 distro

echo "$distro"
echo "source: $Env__LSB_RELEASE"
exit 0

Test__ProgressBar
exit 0

Test__Input__dirpath
Test__Input__dirpath_forcedinput
Test__Str
Test_URL
Test_File
#exit 0

_log_status high "Uploading app..."
sleep 3
_log_status_end ok
_log_status_end fail

exit 0

# END UNFORMAL QUICKTESTS
###############################################################################


:<<'EOF'
Use this function to display the test result

@param [1] boolean result (eg. value of $?). 0=success, otherwise failure
@param [2...n] list of additional infos in case of failure, typically a message of type "got <value>, whilst expected <other value>"
of the basic form xxxxx://yyyyy
@return mirrors first parameter
EOF

Test__printResult()
{
    if [ $1 -eq 0 ] ; then 
        echo SUCCESS
        return 0
    else
        Test__resultAll=1
        echo FAIL
        if [ $# -gt 1 ] ; then
            shift
            local i
            #local args=($@)
            for i in "$*"
            do  
                echo "'$i'"
            done
        fi
        return 1
    fi
    return 0
}

# --------------------------------------------------------------------------------------
# File related API
# --------------------------------------------------------------------------------------


Test_File()
{
    Test__File_in_out File__ext "\
file.txt txt
composite.file.name.with.dots.zip zip
noext \"\"
f.longextension longextension
.so so
\"\" \"\""

   Test__File_in_out File__corename "\
file.txt file
composite.file.name.with.dots.zip composite.file.name.with.dots
noext noext
f.longextension f
.so \"\"
\"\" \"\""
}

Test__File_in_out()
{
    local test_input=()
    test_input+=($2)
    local i=0
    local res
    local expectedres
    local url
    while [ $i -lt ${#test_input[@]} ]
    do
        local file=${test_input[$i]} 
        i=$(($i+1))
        expectedres=${test_input[$i]} 
        Str__trim "$expectedres" expectedres "\""
        local val
        eval $1 "$file" val
#echo "$? ${test_res[$i]}"
        [ "$val" == "$expectedres" ] && res=0 || res=1
        Test__printResult $res "'$1' tests: test fail for value '$file' : got '$val' while '$expectedres' expected."
        i=$(($i+1))
    done
}


# --------------------------------------------------------------------------------------
# Net API
# --------------------------------------------------------------------------------------
Test_URL()
{
    local test_urls=()
    test_urls+=(
        "https://@drive.google.com/" 1
        "https://drive?.google&.com/" 1
        "https://drive.google.com/" 0
        "https://drive.google.com:80/" 0
        "https://drive.google.com:8080/" 0
        "https://drive.google.com" 0
        "https://drive.google.com:80" 0
        "http://drive.google.com" 0 
        "http://drive.google.com:80" 0 
        "http://drive.google.com/" 0
        "http://drive.google.com:80/" 0
        "http://drive.google.com//" 1
        "drive.google.com" 0 
        "drivegoogle.com" 0
        "drivegooglecom" 1
        "a" 1
        "" 1
        "https://askubuntu.com/questions/" 1
    )
    local i=0
    local res
    local expectedres
    local url
    while [ $i -lt ${#test_urls[@]} ]
    do
        url=${test_urls[$i]} 
        i=$(($i+1))
        expectedres=${test_urls[$i]} 
        Net__isHTTP "$url"
#echo "$? ${test_res[$i]}"
        [ $? -eq $expectedres ] && res=0 || res=1
        Test__printResult $res "'$url' was not detected as valid"
        i=$(($i+1))
    done
}

# --------------------------------------------------------------------------------------
# Progress bar test
# --------------------------------------------------------------------------------------

Test__ProgressBar()
{
    local maxsteps=50
    local i=0
    while [ $i -le $maxsteps ] ; do
    
        Term__updateProgressBar "sumo_hang_con" $maxsteps 1
        i=$(($i+1))
    done
    maxsteps=71
    i=0
    while [ $i -le $maxsteps ] ; do
    
        Term__updateProgressBar "sumo_hang_con2" $maxsteps 1
        i=$(($i+1))
    done
}

# --------------------------------------------------------------------------------------
# String tests
# --------------------------------------------------------------------------------------

Test__Str_squeeze_testOneString()
{
    local res
    local ret
    $1 "$2" res
    ret=$?
    [ $ret -eq 0 ] && [ "$res" == "$3" ]
    Test__printResult $? "GOT: '$res', EXPECTED: "$3"" "$ret"
}

Test__Str_escape_testOneString()
{
    local res
    local ret
    $1 "$4" "$2" "$3" res
    ret=$?
    [ $ret -eq 0 ] && [ "$res" == "$5" ]
    Test__printResult $? "$res" "$ret"
}

Test__Str_trim_testOneString()
{
    local res
    local nbTrimmed
    $1 "$2" res
    nbTrimmed=$?
    [ $nbTrimmed -eq $4 ] && [ "$res" == "$3" ]
    Test__printResult $? "$res" "$nbTrimmed"
}

Test__Str()
{
    Test__Str_trim_testOneString Str__trim "   A sentence with some  spaces every   where  " "A sentence with some  spaces every   where" 5
    Test__Str_trim_testOneString Str__trim "nochange" "nochange" 0
    Test__Str_trim_testOneString Str__trim " 1 leading only" "1 leading only" 1
    Test__Str_trim_testOneString Str__trim "1 trailing only " "1 trailing only" 1
    Test__Str_trim_testOneString Str__trim "" "" 0  # empty string
    Test__Str_trim_testOneString Str__trim " " "" 1 # single space

    Test__Str_trim_testOneString Str__trimStart "   A sentence with some  spaces every   where  " "A sentence with some  spaces every   where  " 3
    Test__Str_trim_testOneString Str__trimStart "nochange" "nochange" 0
    Test__Str_trim_testOneString Str__trimStart " 1 leading only" "1 leading only" 1
    Test__Str_trim_testOneString Str__trimStart "1 trailing only " "1 trailing only " 0
    Test__Str_trim_testOneString Str__trimStart "" "" 0  # empty string
    Test__Str_trim_testOneString Str__trimStart " " "" 1 # single space

    Test__Str_trim_testOneString Str__trimEnd "   A sentence with some  spaces every   where  " "   A sentence with some  spaces every   where" 2
    Test__Str_trim_testOneString Str__trimEnd "nochange" "nochange" 0
    Test__Str_trim_testOneString Str__trimEnd " 1 leading only" " 1 leading only" 0
    Test__Str_trim_testOneString Str__trimEnd "1 trailing only " "1 trailing only" 1
    Test__Str_trim_testOneString Str__trimEnd "" "" 0  # empty string
    Test__Str_trim_testOneString Str__trimEnd " " "" 1 # single space

    Test__Str_escape_testOneString Str__escape " " § "   A sentence with some  spaces every   where  " "A§sentence§with§some§§spaces§every§§§where" 0
    Test__Str_escape_testOneString Str__escape " " § "nochange" "nochange" 0
    Test__Str_escape_testOneString Str__escape " " § " 1 leading only" "1§leading§only" 0
    Test__Str_escape_testOneString Str__escape " " § "1 trailing only " "1§trailing§only" 0
    Test__Str_escape_testOneString Str__escape " " § "" "" 0
    Test__Str_escape_testOneString Str__escape " " § " " "" 0        

    Test__Str_squeeze_testOneString Str__squeeze "   A sentence with some  spaces every   where  " " A sentence with some spaces every where " 0
    Test__Str_squeeze_testOneString Str__squeeze "nochange" "nochange" 0
    Test__Str_squeeze_testOneString Str__squeeze " 1 leading only" " 1 leading only" 0
    Test__Str_squeeze_testOneString Str__squeeze "             a lot leading" " a lot leading" 0
    Test__Str_squeeze_testOneString Str__squeeze "1 trailing only " "1 trailing only " 0
    Test__Str_squeeze_testOneString Str__squeeze "a lot trailing                       " "a lot trailing " 0
    Test__Str_squeeze_testOneString Str__squeeze "" "" 0
    Test__Str_squeeze_testOneString Str__squeeze " " " " 0        
    Test__Str_squeeze_testOneString Str__squeeze "           e         " " e " 0        

    local test_string="/home/mike/windows/Users/vault/passwords.vera"
    local expected="/home/mike/wi...passwords.vera"
    local retval
    Str__shrinkToMid test_string 30 "..."
    if [ "$expected" == "$test_string" ] ; then retval=0; else retval=1; fi
    Test__printResult "$retval" "Str__shrinkToMid: Got '$test_string' while '$expected' expected"

    #echo "RESULT: '$test_string'"

    if [ $Test__resultAll -eq 0 ] ; then
        _log "All tests were successful"
    else
        _log_err "At least one test failed"
    fi
}

# --------------------------------------------------------------------------------------
# Input tests
# --------------------------------------------------------------------------------------

# @param [1] command result 0
# @param [2] returned folder
Test__Input__dirpath_checkOutput()
{
    local ret=1
    if [ $1 -eq 0 ] ; then 
        if [ -d "$2" ] ; then
            rmdir "$2"
            echo "'$2' was entered !" >&2
            ret=0
        else
            ret=1
        fi
        Test__printResult $1
    else
        echo "aborted!"
        Test__printResult 0
        ret=0
    fi
    return $ret
}

Test__Input__dirpath() 
{
    local dest=""
    Input__dirpath "Enter mount point" "dir" 0 dest
    Test__Input__dirpath_checkOutput $? "$dest"

}
Test__Input__dirpath_forcedinput() 
{
    local dest=""
    Input__pushForcedInput "yes"
    Input__dirpath "Enter mount point" "dir" 0 dest
    Test__Input__dirpath_checkOutput $? "$dest"
}