#!/bin/bash
#############################################################
#
# Copyright (c) 2024 Michel MEHL
#
#############################################################
MY_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

source "${MY_DIR}/shell-api-core.sh"

if _loaded "${BASH_SOURCE[0]}"  ; then
	return 0
fi

A4_WIDTH_MM=210
A4_HEIGHT_MM=297
PHOTO_WIDTH_MM=150
PHOTO_HEIGHT_MM=100

# Show all time-related ata
# exiftool -time:all -G -a -s   ../04/20230425_164247.mp4
#FileModifyDate FileAccessDate FileInodeChangeDate CreateDate ModifyDate TrackCreateDate TrackModifyDate MediaCreateDate MediaModifyDate 

# Modify creation time:
# NOTE: FileModifyDate is also OK
# NOTE: FileCreateDate is windows only
# exiftool -CreateDate="2023:04:25 16:43:47+02:00" 20230503_180351.mp4
# 
# Create CreateData from FileModifyDate
# exiftool "-CreateDate<FileModifyDate" demo_cannelle_maison/images/2016/06/Micheletcannelle.jpg
# rsync -at to preserve modify date!

:<<'EOF'
Enables the get the actual dimension of an image as returned by exiftool
param[1] Image file path 
param[2] A reference to the variable where to store the dimension in the form of a string "<width> <height>"
EOF
Image__getDimension()
{
    local imageFilePath="$1"
    local -n __out_imagedimension="$2"
    __out_imagedimension="$(exiftool -s3 -S -ImageWidth -ImageHeight "${imageFilePath}")"
}

Image__isPortrait() 
{
    local imageFilePath="$1"
	local rawsize
	Image__getDimension "$imageFilePath" rawsize
    local size=($rawsize) 
	local w=${size[0]}
	local h=${size[1]}
    [ $h -gt $w ]
}

:<<'EOF'
Truncate passed image so that the ratio height/width for portrait images or ratio width/height for landscape images matches ratio.
By the default, the target image file is not overwritten if it already exists , except if fifth argument is specified
<image ratio threshold>
@param [1] source image file
@param [2] width and height separated by a space
@param [3] target base image file name. The target image will have the same extension of source image. Source and target can be the same
@param [4] target image height/width ratio
@param [5] boolean allowing to chop the largest edge if image ratio is greater than the target ratio
@param [6] boolean allowing to chop the shortest edge if image ratio is below the target ratio
@param [7] boolean optional telling whether the target image file shall be overwritten if it exists. Other values means 'no'
@param [8] Gives the image format of the chopped image variante for printable devices. That image is not resized, its name is the source image name
           prefixed with "pdf_" and the ".png" extension. When no extension is specified, it is not generated.
@param [9] Optional target image size if chopped image has to be resized. Chopped image file name and extension is as specified by 3rd argument. 
@param [10] Optional target image size for mobile devices. Chopped image file name and extension for mobiles devices is the same as the normal chopped image
            except that it is prefixed with "mobile_"
            When no specified, the image for mobile is not generated
EOF

Image__chopFromRatio() {
    # Argument checks
    local cutGreatEdge=$5
    local cutSmallEdge=$6
    local overwrite=false
    if [ $# -ge 7 ] ; then
        overwrite=$7
    elif ! Args__checkMinCount ${FUNCNAME[0]} 4 "$#" "Usage: <image file> <(w,h) pair> <target base image file name without ext>  <image ratio threshold>"; then 
        return 1
    fi
    # Arg error checks
    if [ ! -f "$1" ] ; then
        _log_err "File $1 was not found"
        return -1;
    fi

	local original_image="$1"
    local size=($2)
	local title_image_fullfilename="$3"
	local title_image_fullfilename_for_print_devices=""
    local title_image_dir
    local title_image_basename
    File__dirname "$3" title_image_dir
    File__basename "$3" title_image_basename
    #local title_image_fullfilename_noext=""
    #File__noext "${title_image_fullfilename}" title_image_fullfilename_noext
	#local title_image_fileext
    #File__ext "$3" title_image_fileext

    local threshold="$4"
    local onlyChopAsPortrait=false
    local onlyChopAsLanscape=false
    if [ ${threshold:0:1} == "P" ] ; then 
        onlyChopAsPortrait=true;
        threshold=${threshold:1} 
    elif [ ${threshold:0:1} == "L" ] ; then 
        onlyChopAsLanscape=true;
        threshold=${threshold:1} 
    fi

    local fileChanged=false
    local doChop=$overwrite
	if [ ! -f "${title_image_fullfilename}" ] ; then
        doChop=true
    fi

    if [ $# -ge 8 ] ; then
        local title_image_basename_noext
        File__noext "${title_image_basename}" title_image_basename_noext            
        title_image_fullfilename_for_print_devices="${title_image_dir}/pdf_${title_image_basename_noext}.$8"
        if [ ! -f "${title_image_fullfilename_for_print_devices}" ] ; then
            doChop=true
        fi
    fi

    local resizeCmd=""
    local resizeWidth
    local resizeHeight
    if [ $# -ge 9 ] ; then
        resizeCmd="-resize $9"
        Str__split "${9}" resizeWidth "x" resizeHeight 1
    fi
    local resizeCmdMobi=""
    if [ $# -ge 10 ] ; then
        resizeCmdMobi="-resize ${10}"
    fi

	if $doChop ; then
		local h=0
		local w=0
        if [ ${#size[@]} -eq 0 ] ; then
            local rawsize
            Image__getDimension "$original_image" rawsize
            size=($rawsize) 
        fi
        w=${size[0]}
        h=${size[1]}

        local threshold_int=0
        Int__calc_r "$threshold * 1000" threshold_int
		local imRatio_int=0
        local isPortrait=false
        if [ $h -gt $w ] ; then
            isPortrait=true
            Int__calc_r "($h / $w) * 1000" imRatio_int
        else
            isPortrait=false
            Int__calc_r "($w / $h) * 1000" imRatio_int
        fi

        if $onlyChopAsPortrait ; then 
            if ! $isPortrait ; then
                Int__calc_r "($h / $w) * 1000" imRatio_int
            fi
            isPortrait=true; 
        elif $onlyChopAsLanscape ; then 
            if $isPortrait ; then
                Int__calc_r "($w / $h) * 1000" imRatio_int
            fi
            isPortrait=false; 
        fi

        #_log_vars imRatio_int threshold_int threshold isPortrait w h onlyChopAsPortrait onlyChopAsLanscape 

        # Compute ratios

        local excessiveBandPixelSize=0 # Vertical or horizontal
        local cutHeight=false
        local cutWidth=false
        if [ $imRatio_int -ne $threshold_int ] ;  then
            local diff_each_side=0
            # Portrait image is too tall : truncate top/bottom of image 
            if [ $imRatio_int -gt $threshold_int ] && $isPortrait && ! $onlyChopAsLanscape; then 
                #_log "Portrait image is too tall : truncate top/bottom of image "
                if $cutGreatEdge ; then
                    Int__calc_r "($h - ($w*${threshold}))/2" diff_each_side 
                    #Int__calc_r "($h - (($h*${threshold_int}) / ${imRatio_int}))/2" diff_each_side 
                    cutHeight=true
                fi
            # Landscape image is too tall : truncate top/bottom of image
            elif [ $imRatio_int -lt $threshold_int ] && ! $isPortrait && ! $onlyChopAsPortrait ; then
                #_log "Landscape image is too tall : truncate top/bottom of image"
                if $cutSmallEdge ; then
                    Int__calc_r "($h - ($w/${threshold}))/2" diff_each_side 
                    #Int__calc_r "($h - (($h*${imRatio_int}) / ${threshold_int}))/2" diff_each_side 
                    cutHeight=true
                fi
            # Portrait image is too large: truncate left/right of image
            elif [ $imRatio_int -lt $threshold_int ] && $isPortrait && ! $onlyChopAsLanscape;  then 
                if $cutSmallEdge ; then
                    Int__calc_r "($w - (($h) / ${threshold}))/2" diff_each_side 
                    #Int__calc_r "($w - (($w*${imRatio_int}) / ${threshold_int}))/2" diff_each_side 
                    cutWidth=true
                fi
                #_log "Portrait image is too large: truncate left/right of image"
                #_log_vars w threshold diff_each_side
            # Landscape image is too large : truncate left/right of image
            elif [ $imRatio_int -gt $threshold_int ] && ! $isPortrait && ! $onlyChopAsPortrait;  then                 
                #_log "Landscape image is too large : truncate left/right of image"
                if $cutGreatEdge ; then
                    Int__calc_r "($w - ($h*${threshold}))/2" diff_each_side 
                    #Int__calc_r "($w - (($w*${threshold_int}) / ${imRatio_int}))/2" diff_each_side 
                    cutWidth=true
                fi
            fi

            _log_dbg " Image__chopFromRatio +++ cutWidth=$cutWidth, cutHeight=$cutHeight, imRatio =$imRatio_int, threshold=$threshold_int, isPortrait=$isPortrait, w=${w}, h=${h}, rm each side=${diff_each_side}, nbArg=$#, resize=${resizeCmd}"

            if (( ${diff_each_side} > 1 )) ; then
                if $cutHeight ; then
                    _log_dbg "Picture is too tall, remove ${diff_each_side} pixels at top and bottom"
                    local cmd1=""
                    local cmd1bis=""
                    local cmd2=""
                    local cmd3=""

                    if [ -z "${title_image_fullfilename_for_print_devices}" ] ; then
                        cmd1="convert -define preserve-timestamp=true -gravity North -chop \"0x${diff_each_side}\" -gravity South -chop \"0x${diff_each_side}\"  \"$1\" \"${title_image_fullfilename}\""
                    else
                        cmd1="convert -define preserve-timestamp=true -gravity North -chop \"0x${diff_each_side}\" -gravity South -chop \"0x${diff_each_side}\"  \"$1\" \"${title_image_fullfilename_for_print_devices}\""
                        cmd1bis="convert \"${title_image_fullfilename_for_print_devices}\" \"${title_image_fullfilename}\""
                    fi

                    if [ ! -z "${resizeCmdMobi}" ] ; then
                        cmd3="convert ${resizeCmdMobi} \"${title_image_fullfilename}\" \"${title_image_dir}/mobile_${title_image_basename}\""
                    fi
                    if [ ! -z "${resizeCmd}" ] ; then
                        #cmd2="mogrify -define preserve-timestamp=true -gravity South -chop \"0x${diff_each_side}\" \"${title_image_fullfilename}\""
                    #else
                        #cmd2="mogrify \"${title_image_fullfilename}\" -define preserve-timestamp=true -gravity South -chop \"0x${diff_each_side}\" && mogrify \"${title_image_fullfilename}\" ${resizeCmd}"
                        cmd2="mogrify ${resizeCmd} \"${title_image_fullfilename}\""
                    fi
					_logf "Executing command: ${cmd1}"
					eval "$cmd1"
                    if [ $? -ne 0 ] ; then _log_warn "Failed to chop north/south image '$1': $cmd1" ; fi
                    if [ ! -z "${cmd1bis}" ] ; then
				    	_logf "Executing command: ${cmd1bis}"
					    eval "$cmd1bis"
                        if [ $? -ne 0 ] ; then _log_warn "Failed $cmd1bis" ; fi
                    fi                    
                    if [ ! -z "${cmd2}" ] ; then
                        local doResize=false
                        if [ $resizeWidth -lt $w ] && ! $isPortrait ; then doResize=true; fi
                        if [ $resizeHeight -lt $h ] && $isPortrait ; then doResize=true; fi
                        #_log_dbg "$resizeWidth < $w ?  $resizeHeight < $h?"
                        if $doResize; then # Only resize when the image would be smaller according to its orientation
                            _logf "Executing command: ${cmd2}"
                            eval "$cmd2"
                            if [ $? -ne 0 ] ; then _log_warn "Failed to resize '$1' to '${title_image_fullfilename}'" ; fi
                        fi
                    fi
                    if [ ! -z "${cmd3}" ] ; then
    					_logf "Executing command: ${cmd3}"
    					eval "$cmd3"
                        if [ $? -ne 0 ] ; then _log_warn "Failed to resize image '$1' to '${title_image_fullfilename}' for mobile" ; fi
                    fi
                elif $cutWidth ; then
                    _log_dbg "Picture is too large, remove ${diff_each_side} pixels at left and right"
                    local cmd1="convert -define preserve-timestamp=true -gravity East -chop \"${diff_each_side}x0\" -gravity West -chop \"${diff_each_side}x0\" \"$1\" \"${title_image_fullfilename}\""
                    local cmd1bis=""
                    local cmd2=""
                    local cmd3=""
                    if [ -z "${title_image_fullfilename_for_print_devices}" ] ; then
                        cmd1="convert -define preserve-timestamp=true -gravity East -chop \"${diff_each_side}x0\" -gravity West -chop \"${diff_each_side}x0\" \"$1\" \"${title_image_fullfilename}\""
                    else
                        cmd1="convert -define preserve-timestamp=true -gravity East -chop \"${diff_each_side}x0\" -gravity West -chop \"${diff_each_side}x0\" \"$1\" \"${title_image_fullfilename_for_print_devices}\""
                        cmd1bis="convert \"${title_image_fullfilename_for_print_devices}\" \"${title_image_fullfilename}\""
                    fi

                    if [ ! -z "${resizeCmdMobi}" ] ; then
                        cmd3="convert ${resizeCmdMobi} \"${title_image_fullfilename}\" \"${title_image_dir}/mobile_${title_image_basename}\""
                    fi
                    if [ ! -z "${resizeCmd}" ] ; then
                        #cmd2="mogrify -define preserve-timestamp=true -gravity West -chop \"${diff_each_side}x0\" \"${title_image_fullfilename}\""
                    #else
                        #cmd2="mogrify \"${title_image_fullfilename}\" -define preserve-timestamp=true -gravity West -chop \"${diff_each_side}x0\" && mogrify \"${title_image_fullfilename}\" ${resizeCmd}"
                        cmd2="mogrify ${resizeCmd} \"${title_image_fullfilename}\""                        
                    fi
					_logf "Executing command: ${cmd1}"
					eval "$cmd1"
                    if [ $? -ne 0 ] ; then _log_warn "Failed to chop west/east image '$1': $cmd1" ; fi
                    if [ ! -z "${cmd1bis}" ] ; then
				    	_logf "Executing command: ${cmd1bis}"
					    eval "$cmd1bis"
                        if [ $? -ne 0 ] ; then _log_warn "Failed $cmd1bis" ; fi
                    fi                    

                    if [ ! -z "${cmd2}" ] ; then
                        local doResize=false
                        if [ $resizeWidth -lt $w ] && ! $isPortrait ; then doResize=true; fi
                        if [ $resizeHeight -lt $h ] && $isPortrait ; then doResize=true; fi
                        #_log_dbg "$resizeWidth < $w ?  $resizeHeight < $h?"
                        if $doResize; then # Only resize when the image would be smaller according to its orientation
                            _logf "Executing command: ${cmd2}"
                            eval "$cmd2"
                            if [ $? -ne 0 ] ; then _log_warn "Failed to resize image '$1' to '${title_image_fullfilename}'" ; fi
                        fi
                    fi
                    if [ ! -z "${cmd3}" ] ; then
    					_logf "Executing command: ${cmd3}"
    					eval "$cmd3"
                        if [ $? -ne 0 ] ; then _log_warn "Failed to resize image '$1' to '${title_image_fullfilename}' for mobile" ; fi
                    fi
                fi

                fileChanged=true
            fi
		fi
    else
        _log_dbg "${FUNCNAME[0]} : file '${title_image_fullfilename}' already exists"
	fi

    if ! $fileChanged ; then
        local cmd1=""
        local cmd1bis=""
        local cmd2=""
        local cmd3=""
        _log_dbg " Image__chopFromRatio file changed ? '$fileChanged' "

        #rsync -a "$1" "${title_image_fullfilename}"

        if [ -z "${title_image_fullfilename_for_print_devices}" ] ; then
            cmd1="convert \"$1\" \"${title_image_fullfilename}\""
        else
            cmd1="convert \"$1\" \"${title_image_fullfilename_for_print_devices}\""
            cmd1bis="convert \"${title_image_fullfilename_for_print_devices}\" \"${title_image_fullfilename}\""
        fi
        if [ ! -z "${resizeCmdMobi}" ] ; then
            cmd3="convert ${resizeCmdMobi} \"${title_image_fullfilename}\" \"${title_image_dir}/mobile_${title_image_basename}\""
        fi
        if [ ! -z "${resizeCmd}" ] ; then
            cmd2="mogrify ${resizeCmd} \"${title_image_fullfilename}\""
        fi

        _logf "Executing command: ${cmd1}"
        eval "$cmd1"
        if [ $? -ne 0 ] ; then _log_warn "Failed to chop north/south image '$1': $cmd1" ; fi
        if [ ! -z "${cmd1bis}" ] ; then
            _logf "Executing command: ${cmd1bis}"
            eval "$cmd1bis"
            if [ $? -ne 0 ] ; then _log_warn "Failed $cmd1bis" ; fi
        fi                    
        if [ ! -z "${cmd2}" ] ; then
            _logf "Executing command: ${cmd2}"
            eval "$cmd2"
            if [ $? -ne 0 ] ; then _log_warn "Failed to resize '$1' to '${title_image_fullfilename}'" ; fi
        fi
        if [ ! -z "${cmd3}" ] ; then
            _logf "Executing command: ${cmd3}"
            eval "$cmd3"
            if [ $? -ne 0 ] ; then _log_warn "Failed to resize image '$1' to '${title_image_fullfilename}' for mobile" ; fi
        fi
    fi
    return 0
}


Image__autoOrient()
{
    mogrify -define preserve-timestamp=true -auto-orient "$1"
}

:<<'EOF'
@param image file with extension
@param target image file with extension
@param boolean (0/1) telling whether to overwrite existing (false by default)
@param return 0 if a change was done , 1 otherwise. Prints new width, height and orientation as returned by exiftool
EOF
Image__normalizeOrientation() {
    local f="$1"
    local t="$2"
    local f_propsAsArray=($(exiftool -s3 -ImageWidth -ImageHeight -Orientation "$f"))
    local im_dim=${f_propsAsArray[@]:0:2}
    _log_dbg  "${FUNCNAME[0]} '${#f_propsAsArray[@]}' '${f_propsAsArray[@]}' '$im_dim' '${im_dim[@]}' orientation: '${f_propsAsArray[2]}'"
    if [ ! -z "${f_propsAsArray[2]}" ] ; then
        if ! Str__startsWith "${f_propsAsArray[2]}" "Horizontal" ; then
            printf "\rAuto-orienting image $(basename "$f") (${f_props[2]})"            
            #cp  "$f" "$t"
            #mogrify -define preserve-timestamp=true -auto-orient "$t" 
            convert "$f" -define preserve-timestamp=true -auto-orient "$t" # TEST / WHY THE ABOVE LINES??
        else
            # Files may have different extensions
            convert "$f" "$t"
            #File__mirrorCopy "$f" "$t"
        fi
    else
            # Files may have different extensions
            convert "$f" "$t"
            #File__mirrorCopy "$f" "$t"
    fi
    # Return value is the return value of last executed commands
}

SVG_text() {
    local porth=$1
    local txt="$2"
    local style="$3"
    local y=$4
    local fontwidthfactor="$5"
    local bgcolor="$6"
    local rounding="auto"
    local width=0
    local trimmedFontwidthfactor="${fontwidthfactor#\**}"
    if [ "$trimmedFontwidthfactor" = "$fontwidthfactor" ] ; then
        width="$fontwidthfactor" # "$fontwidthfactor" is an actual size, not a factor
    else
        width="$(( ${#txt} * $trimmedFontwidthfactor ))"
    fi
    local x="$(( $width / 2 ))"
    #y=$fontsize

    if [ $# -ge 7 ] ; then
        rounding="$7"
    fi

    local rectw=$(($width-10))
    local recth=$(($porth-10))

#        width="$width" height="$porth"
cat << EOF
    <svg version="1.1"
        viewBox="0 0 $width $porth"
        xmlns="http://www.w3.org/2000/svg">

        <defs>
            <filter id="shadow">
                <feGaussianBlur in="SourceAlpha" stdDeviation="3"/> <!-- stdDeviation is how much to blur -->
                <feOffset dx="2" dy="2" result="offsetblur"/> <!-- how much to offset -->
                <feComponentTransfer>
                    <feFuncA type="linear" slope="0.9"/> <!-- slope is the opacity of the shadow -->
                </feComponentTransfer>
                <feMerge>
                    <feMergeNode/> <!-- this contains the offset blurred image -->
                    <feMergeNode in="SourceGraphic"/> <!-- this contains the element that the filter is applied to -->
                </feMerge>
            </filter>
        </defs>

        <style>
          $style
        </style>     
        <rect width="100%" height="100%" class="banner" fill="$bgcolor" rx="$rounding"/>
        <text x="$x" y="$y" class="small" text-anchor="middle">$txt</text>
    </svg>
EOF
#        <rect x="5" y="5" width="$rectw" height="$recth" fill="$bgcolor" rx="$rounding"/>

#display "$file"

}

:<<'EOF'
Generates .ico from another image format in the specified target directory. 
The target icon will have the same as the original image and stored in the same folder.
@param [1] source image file
EOF
Image__ico()
{
    if ! Args__checkCount ${FUNCNAME[0]} 1 "$#" "Usage: <image file>"; then 
        return 1
    fi

    if [ ! -f "$1" ] ; then 
        _log_err "${FUNCNAME[0]}: $1 does not exist"
        return 1
    fi

	local inputImage="$1"
    local dir=""
    local iconame=""
    File__dirname "$inputImage" dir
    File__corename "$inputImage" iconame
    iconame="${iconame}.ico"

	convert -background transparent "${inputImage}" -define icon:auto-resize=16,24,32,48,64,72,96,128,256 "${dir}/${iconame}"
    # Return value is that of 'convert'
}

:<<'EOF'
Generates files of the form 
<PDF filebasename>-<image PPI>-<page>.jpg

@param [1] in pdffile path
@param [2] in output directory
@param [3] out list of files generated
@param [4] in output image format
@param [5] in output image PPI resolution
@param [6] in other options

pfgtocairo:
resolution: -r, -rx , -ry (default is 150 PPI)
-transp for transparent background with PNG
EOF
Image__generateFromPDF()
{
    _loadDep "pdftocairo@poppler-utils"

    local __in_pdffile="$1"
    local __in_outdirPath="$2"
    local -n __out_filelist=$3
    local __in_imageFormat="jpeg"
    local __in_imageRes=150
    local __in_options=""
    if [ $# -ge 4 ] ; then __in_imageFormat="$4" ; fi
    if [ $# -ge 5 ] ; then __in_imageRes="$5" ; fi
    if [ $# -ge 6 ] ; then __in_options="$6" ; fi

    if ! Args__checkMinCount ${FUNCNAME[0]} 2 "$#" "Usage: <PDF file> <target outputdir> [<output image format>]"; then 
        return 1
    fi

    if [ ! -f "${__in_pdffile}" ] ; then
        _log_err "'${__in_pdffile}' is an invalid file."
        return -1;
    fi
    if [ ! -d "${__in_outdirPath}" ] ; then
        _log_err "'${__in_outdirPath}' is an invalid target folder."
        return -1;
    fi
    
    local pdfFileRealPath="$(realpath "${__in_pdffile}")"
    local pdfBasename
    #File__basename "${__in_pdffile}" pdfBasename
    File__corename "${__in_pdffile}" pdfBasename

    pushd "${__in_outdirPath}" &>/dev/null
    if [ $? -eq 0 ] ; then
        #gs -dNOPAUSE -sDEVICE=pngalpha -r300 -dFirstPage=1 -dLastPage=200 -sOutputFile="${pdfBasename}-%03d.png" "${__in_pdffile}" -c

        # -f <start page no> -l <nb pages> for specific page range
        local outputFile="${pdfBasename}-${__in_imageRes}"
        local cmd="pdftocairo ${__in_options} -r ${__in_imageRes} -${__in_imageFormat} '${pdfFileRealPath}' '${outputFile}'" 
        _log "Executing '$cmd'" # | tee -a "${__LOG_ERR_FILE__}"
        eval "$cmd" 1>/dev/null 2>&1 | tee -a "${__LOG_ERR_FILE__}"
        if [ $? -eq 0 ] ; then
            __out_filelist+=($(ls -1 "${outputFile}"*)) #"${__in_outdirPath}/${outputFile}"))
        fi

        popd &>/dev/null
    else
        _log_err "Failed to cd to '${__in_outdirPath}'. Permission denied?"
        return -1;
    fi
}

Image__generatePDFFromImageFiles()
{
    _loadDep "pdftocairo@poppler-utils"

    local __output_pdffile="$1"
    local __in_outdirPath="$2"
    local -n __in_filelist=$3
    convert "${__in_filelist[@]}" "${__in_outdirPath}/${__output_pdffile}" 
}

Image__watermark()
{
	local threadPool=()

    local -n fileList=$1
    local filesDir="$2"
    local outputDir="$3"
    local watermarkImage="$4"
    local -n __out_fileLists=$5
    local threadPoolSize=1
    local width=0
    if [ $# -eq 6 ] ; then threadPoolSize=$6 ; fi

	Sys__pool_init threadPool "Image__watermark" "${threadPoolSize}"

    local i=""
    for i in "${fileList[@]}"  ; do
        local f="${filesDir}/${i}"
        local outputFilename="watermarked_${i}"
        local outputFile="${outputDir}/${outputFilename}"
        read width< <(exiftool -s3 -ImageWidth "$f")
        #_log_dbg "pool($threadPoolSize) convert \"$f\" \\( ${watermarkImage} -resize "${width}x" \\) -gravity center -composite \"${outputFile}\""

        Sys__pool_spawn threadPool convert \"$f\" \\\( \"${watermarkImage}\" -resize \"${width}x\" \\\) -gravity center -composite \"${outputFile}\"
        __out_fileLists+=("${outputFilename}")

    done

	local resultRetVal
	Sys__pool_waitall threadPool
	resultRetVal=$?
	return $resultRetVal
}