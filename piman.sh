#! /bin/bash 

E_ARGERROR=2
REBOOT_ERROR=3
HOST_DNE_ERROR=4
REBOOT=0
SCRIPT_DIR=/home/pi/scripts
PI=""
APP=""
WEBPAGE=""
VIDEO_PATH=""
I_WANT_IT_NOW=""

##functions
UsageDoc ()
{
    cat <<End-Of-Documentation
        
    
        Usage: 
	$0 
	[ -b | -h | -km | -ko | -m [url] | -mn [url]  
	| -o [path] | -on [path] | -p [hostname] | -pc  
	| -pcn | -r | -u ] 

	Options:
	-b   | --blank	      Blank the monitor using dpms
	-h   | --help         Show this help menu
	-km  | --kill-midori  Kills all midori processes
	-ko  | --kill-omx     Kills all omxplayer processes
	-m   | --midori       Use midori with the url 
			      (either provided or default)
	-mn  | --midori-now   You want midori now, not later		    
	-o   | --omxplayer    Use Omxplayer with path 
			      (either provided or default)
	-on  | --omx-now      You want omxplayer now!		    
	-p   | --pi 	      Host to control (use ALL for all) 
	-pc  | --prev-cfg     Reverse changes made last
	-pcn | --prev-cfg-now Reverse changes immediately
	-r   | --reboot       Apply the settings then reboot
	-u   | --unblank      Unblank the monitor using dpms


End-Of-Documentation
exit
}

#use like: Remote_CMD [pseudo command] [host] [webpage/path]
Remote_CMD ()
{
    case $1 in
	reboot)
	    CMD2RUN="sudo shutdown -r now"
	    ;;
	blank)
	    CMD2RUN="sleep 1 && xset -display :0 s blank && xset -display :0 dpms force off"
	    ;;
	unblank)
	    CMD2RUN="xset -display :0 s reset && ${SCRIPT_DIR}/dpms_disable.sh"
	    ;;
	midori)
	    if [ ! -z "$3" ]; then
		#there is a url
		CMD2RUN="${SCRIPT_DIR}/AppMan.sh -a midori -p $WEBPAGE"
	    else
		#there is no url
		CMD2RUN="${SCRIPT_DIR}/AppMan.sh -a midori"
	    fi
	    ;;
	omxplayer)
	    if [ ! -z "$3" ]; then
		#there is a path
		CMD2RUN="${SCRIPT_DIR}/AppMan.sh -a omxplayer -p $VIDEO_PATH"
	    else
		#there is no path
		CMD2RUN="${SCRIPT_DIR}/AppMan.sh -a omxplayer"
	    fi
	    ;;
	killMidori)
	    CMD2RUN="killall midori"
	    ;;
	killOmx)
	    CMD2RUN="killall omxplayer.bin"
	    ;;
    esac
    echo "Sending $1 command.."
    case $2 in
	ALL | all)
	   #ssh keys should be configured already
	   #along with ~/.ssh/config or /etc/hosts
	   ssh rpi1 $(echo -n $CMD2RUN)
	   ssh rpi2 $(echo -n $CMD2RUN)
	   ssh rpi3 $(echo -n $CMD2RUN) 
	   ;;
	1 | rpi1)
	   ssh rpi1 $(echo -n $CMD2RUN)
	   ;;
	2 | rpi2)
	   ssh rpi2 $(echo -n $CMD2RUN) 
	   ;;
	3 | rpi3)
	   ssh rpi3 $(echo -n $CMD2RUN) 
	   ;;
    esac

}

numopts=$#

#Option Processing
while [ "$1" != "" ]; do
  case $1 in
    -b | --blank)
	BLANK=1 >&2 >&-
	;;
    -h | --help)
        UsageDoc #function def above
       ;;
    -km | --kill-midori)
	KILL_MIDORI=1 >&2 >&-
	;;
    -ko | --kill-omx)
	KILL_OMX=1 >&2 >&-
	;;
    -m | --midori)
       APP="midori"
       if [[ "$2" != "" && $( echo "$2" | grep -v ^-. | grep -v ^--. ) ]];then
           shift #move positional params
	   WEBPAGE=$1
       fi
       ;;
    -o | --omxplayer)
       APP="omxplayer"
       if [[ "$2" != "" && $( echo "$2" | grep -v ^-. | grep -v ^--. ) ]];then
           shift #move positional params
	   VIDEO_PATH=$1
       fi
       ;;
    -p | --pi)   
       shift #move positional params
       if [[ "$1" != "" && $( echo "$1" | grep -v ^-. | grep -v ^--. ) ]];then
           PI=$1
	   if [[ ! $( echo "$PI" | egrep -i "^rpi[1-3]$|^[1-3]$|^ALL$" ) ]]; then
	       echo "Host does not exist: $PI" && echo ""
	       exit $HOST_DNE_ERROR
	   fi
       else
	   echo "" && echo "Option -p or --pi requires an argument." && echo ""
	   UsageDoc
	   exit
       fi
       ;;
    -r | --reboot)
        REBOOT=1 >&2 >&-
       ;;
    -u | --unblank)
	UNBLANK=1 >&2 >&-
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
elif [ -z "$PI" ]; then
    echo "You must specify a host..."
    UsageDoc
fi

#blank or unblank (priority to unblank) but not both
if [[ "$UNBLANK" == "1" ]]; then
    Remote_CMD unblank $PI
    echo "Screen on $PI has been activated"'!'
elif [[ "$BLANK" == "1" ]]; then
    Remote_CMD blank $PI
    echo "Screen on $PI has been blanked"'!'
fi

if [[ "$APP" != "" ]]; then
    if [[ "$APP" == "midori" ]]; then
	if [ ! -z "$WEBPAGE" ]; then
	    Remote_CMD midori "$PI" "$WEBPAGE"
	else
	    Remote_CMD midori "$PI"
	fi
    elif [[ "$APP" == "omxplayer" ]]; then
	if [ ! -z "$VIDEO_PATH" ]; then
	    Remote_CMD omxplayer "$PI" "$VIDEO_PATH"
	else 
	    Remote_CMD omxplayer "$PI"
	fi
    fi
fi

if [[ "$KILL_MIDORI" == "1" ]]; then
    Remote_CMD killMidori "$PI"
    echo "Application Killed.."
elif [[ "$KILL_OMX" == "1" ]]; then
    Remote_CMD killOmx "$PI"
    echo "Application Killed.."
fi

if [[ "$REBOOT" == "1" ]]; then
    Remote_CMD reboot "$PI"
    echo "System $PI will reboot now"'!'
fi

