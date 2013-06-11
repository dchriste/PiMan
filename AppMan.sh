#! /bin/bash

SCRIPT_DIR=/home/pi/scripts
CURRENT_APP=$( grep -v '^#' ${SCRIPT_DIR}/app2start | grep -m1 .. | cut -f1 -d' ' )
CURRENT_URL=$( grep -v '^#' ${SCRIPT_DIR}/homepage | grep -m1 .. )
CURRENT_PATH=$( grep -v '^#' ${SCRIPT_DIR}/video2play | grep -m1 .. )

UsageDoc ()
{
    cat <<End-Of-Documentation
        
    
        Usage: 
	$0 [ -a [app name] | -h | -p [path/url] ] 

	Options:
	-a | --app	   The app to start on reboot
	-h | --help        Show this help menu
	-p | --path 	   The desired path or url to be changed


End-Of-Documentation
exit
}

numopts=$#

#Option Processing
while [ "$1" != "" ]; do
  case $1 in
    -a | --app)
	shift #move positional params
        if [[ "$1" != "" && $( echo "$1" | grep -v ^-. | grep -v ^--. ) ]]; then
           DESIRED_APP=$1
	else
	   echo "" && echo "Option -a or --app requires an argument." && echo ""
	   UsageDoc
	   exit
        fi
	;;
    -h | --help)
        UsageDoc #function def above
       ;;
    -p | --path)   
        shift #move positional params
        if [[ "$1" != "" && $( echo "$1" | grep -v ^-. | grep -v ^--. ) ]]; then
           DESIRED_PATH=$1
	else
	   echo "" && echo "Option -p or --path requires an argument." && echo ""
	   UsageDoc
	   exit
        fi
       ;;
    -*)
       echo "Invalid option: -$1. See usage below..." >&2
       UsageDoc
       exit $E_ARGERROR
       ;;
     *)
       UsageDoc
  esac
  shift #move positional parameters
done

if [ "$numopts" -le 1 ]; then
   #NoArgs
   UsageDoc
elif [ -z "$DESIRED_APP" ]; then
    echo "You must supply an app to modify.."
    UsageDoc
fi

if [[ "$CURRENT_APP" != "$DESIRED_APP" ]]; then
    #change to the desired app (which must already be in the app2start file)
    sed --in-place=.bak -e "s/\(^${CURRENT_APP}\)/#${CURRENT_APP}/g;s/\(^#${DESIRED_APP}\)/${DESIRED_APP}/g;" ${SCRIPT_DIR}/app2start
fi

echo "Desired App has been set.."

#if there is a path/url to change then do so
if [ ! -z "$DESIRED_PATH" ]; then
    if [[ "$DESIRED_APP" == "omxplayer" ]]; then
        if [[ "$CURRENT_PATH" != "$DESIRED_PATH" ]]; then
	    #change the path in video2play (assumes all other paths are commented out)
	    sed --in-place=.bak -e "s_\(^${CURRENT_PATH}\)_#${CURRENT_PATH}_g;" ${SCRIPT_DIR}/video2play
	    echo "$DESIRED_PATH" >> ${SCRIPT_DIR}/video2play
        fi
    elif [[ "$DESIRED_APP" == "midori" ]]; then
        if [[ "$CURRENT_URL" != "$DESIRED_PATH" ]]; then
	    #change the url to desired in homepage (assumes all other urls are commented out)
	    sed --in-place=.bak -e "s|\(^${CURRENT_URL}\)|#${CURRENT_URL}|g;" ${SCRIPT_DIR}/homepage
	    echo "$DESIRED_PATH" >> ${SCRIPT_DIR}/homepage

        fi
    fi
    echo "Desired path/url has been set.."
fi

echo 'App Management complete!'

