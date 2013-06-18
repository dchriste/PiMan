#! /bin/bash 

E_ARGERROR=2
REBOOT_ERROR=3
HOST_DNE_ERROR=4
APP_ERROR=5
REBOOT=0
SCRIPT_DIR=/home/pi/scripts
PI=""
APP=""
WEBPAGE=""
VIDEO_PATH=""
I_WANT_IT_NOW=""

#Define Max Number of Pis in existance
NUMPIS=3

##functions
UsageDoc ()
{
    cat <<End-Of-Documentation
        
    
        Usage: 
	$0 
	[ -b | -h | -km | -ko | -l | -m [url] | -mn [url]  
	| -o [path] | -on [path] | -p [hostname] | -pc  
	| -pcn | -r | -u ] 

	Options:
	-b   | --blank	      Blank the monitor using dpms
	-h   | --help         Show this help menu
	-km  | --kill-midori  Kills all midori processes
	-ko  | --kill-omx     Kills all omxplayer processes
	-l   | --list	      List the current configuration
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
	    CMD2RUN="sleep 1 && xset -display :0 s blank && xset -display :0 dpms force off && touch /tmp/screenblanked"
	    ;;
	unblank)
	    CMD2RUN="xset -display :0 s reset && ${SCRIPT_DIR}/dpms_disable.sh && rm /tmp/screenblanked > /dev/null"
	    ;;
	midori)
	    if [ ! -z "$I_WANT_IT_NOW" ]; then
		TMPCMD="--app midori --now >&- "
	    else
		TMPCMD="--app midori >&- " 
	    fi
	    if [ ! -z "$3" ]; then
		#there is a url
		CMD2RUN="${SCRIPT_DIR}/AppMan.sh --path $WEBPAGE ${TMPCMD}"
	    else
		#there is no url
		CMD2RUN="${SCRIPT_DIR}/AppMan.sh ${TMPCMD}"
	    fi
	    ;;
	omxplayer)
	    if [ ! -z "$I_WANT_IT_NOW" ]; then
		TMPCMD="--app omxplayer --now >&- "
	    else
		TMPCMD="--app omxplayer >&- " 
	    fi
	    if [ ! -z "$3" ]; then
		#there is a path
		CMD2RUN="${SCRIPT_DIR}/AppMan.sh --path $VIDEO_PATH ${TMPCMD}"
	    else
		#there is no path
		CMD2RUN="${SCRIPT_DIR}/AppMan.sh ${TMPCMD}"
	    fi
	    ;;
	killMidori)
	    CMD2RUN="killall midori > /dev/null"
	    ;;
	killOmx)
	    CMD2RUN="killall omxplayer.bin 2>&1>&- && sleep 1 && xrefresh -display :0"
	    ;;
	revert)
	    if [ ! -z "$I_WANT_IT_NOW" ]; then
		TMPCMD="--revert --now" 
	    else
		TMPCMD="--revert"
	    fi
	    CMD2RUN="${SCRIPT_DIR}/AppMan.sh ${TMPCMD} >&- "
	    ;;
	savePrevCFG)
	    #passing the string indicating what has been changed
	    CMD2RUN="mv ${SCRIPT_DIR}/previousConfig ${SCRIPT_DIR}/previousConfig.bak && echo $3 > ${SCRIPT_DIR}/previousConfig"
	    ;;
	 list)
	    CMD2RUN="${SCRIPT_DIR}/AppMan.sh --list"
	    ;;
    esac
    #echo "Sending $1 command.."
    case $2 in
	ALL | all)
	   #ssh keys should be configured already
	   #along with ~/.ssh/config or /etc/hosts
	   for $host in {1..$NUMPIS}; do
	       ssh -n -p 13524 pi@brkrpikiosk${host} "$(echo -n $CMD2RUN) 2>&- &"
	   done
	   ;;
	[0-$NUMPIS])
	   ssh -n -p 13524 pi@brkrpikiosk${2} "$(echo -n $CMD2RUN) 2>&- &"
	   ;;
    esac
}

SavePreviousCFG ()
{
    
    PREVIOUS_CFG=""

    #Write to Previous config file unless it is revert time
    if [ -z  "$REVERT" -a -z "$LIST_CONFIG" ]; then     
	if [ ! -z "$UNBLANK" ]; then
             PREVIOUS_CFG=$(echo "${PREVIOUS_CFG} unblank")
        fi
        if [ ! -z "$BLANK" ]; then
             PREVIOUS_CFG=$(echo "${PREVIOUS_CFG} blank")
        fi
        if [ ! -z "$APP" ]; then
             PREVIOUS_CFG=$(echo "${PREVIOUS_CFG} $APP")
        fi
        if [ ! -z "$KILL_MIDORI" ]; then
             PREVIOUS_CFG=$(echo "${PREVIOUS_CFG} killMidori")
        fi
        if [ ! -z "$KILL_OMX" ]; then
             PREVIOUS_CFG=$(echo "${PREVIOUS_CFG} killOmx")
        fi
	if [ ! -z "$WEBPAGE" -o ! -z "$VIDEO_PATH" ]; then
             PREVIOUS_CFG=$(echo "${PREVIOUS_CFG} path")
        fi
	if [ ! -z "$I_WANT_IT_NOW" ]; then
             PREVIOUS_CFG=$(echo "${PREVIOUS_CFG} now")
        fi

        Remote_CMD savePrevCFG "$PI" "$PREVIOUS_CFG"

    else
	sleep 0; #revert config do not save over prev cfg
    fi
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
    -l  | --list)
        LIST_CONFIG=1 >&2 >&-
        ;;
    -m | -mn | --midori | --midori-now)
       if [ -z "$APP" ]; then
	   APP="midori"
       else
	   #APP is already set, you can't have omx and midori...
	   echo "You have already set App to $APP, pick one App not multiple."
	   exit $APP_ERROR
       fi

       if [[ "$1" == "-mn" || "$1" == "--midori-now" ]]; then
	   I_WANT_IT_NOW=1 >&2 >&-
       fi

       if [[ "$2" != "" && $( echo "$2" | grep -v ^-. | grep -v ^--. ) ]];then
           shift #move positional params
	   WEBPAGE=$1
       fi
       ;;
    -o | -on | --omxplayer | --omx-now)
       if [ -z "$APP" ]; then
	   APP="omxplayer"
       else
	   #APP is already set, you can't have omx and midori...
	   echo "You have already set App to $APP, pick one App not multiple."
	   exit $APP_ERROR
       fi

       if [[ "$1" == "-on" || "$1" == "--omx-now" ]]; then
	   I_WANT_IT_NOW=1 >&2 >&-
       fi

       if [[ "$2" != "" && $( echo "$2" | grep -v ^-. | grep -v ^--. ) ]];then
           shift #move positional params
	   VIDEO_PATH=$1
       fi
       ;;
    -p | --pi)   
       shift #move positional params
       if [[ "$1" != "" && $( echo "$1" | grep -v ^-. | grep -v ^--. ) ]];then
           PI=$1
	   if [[ ! $( echo "$PI" | egrep -i "^rpi[1-$NUMPIS]$|^[1-$NUMPIS]$|^ALL$" ) ]]; then
	       echo "Host does not exist: $PI" && echo ""
	       exit $HOST_DNE_ERROR
	   else
		#host does exist
		if [[ "$PI" =~ "rpi" ]]; then
		    PI=$(echo "$PI" | cut -f2 -d'i')
		fi
	   fi
       else
	   echo "" && echo "Option -p or --pi requires an argument." && echo ""
	   UsageDoc
	   exit
       fi
       ;;
    -p[0-$NUMPIS])
       PI=$(echo "$1" | cut -f2 -d'p')
       ;;
    -pc | -pcn | --prev-cfg | --prev-cfg-now)
       if [[ "$1" == "-pcn" || "$1" == "--prev-cfg-now" ]]; then
	   I_WANT_IT_NOW=1 >&2 >&-
       fi

       REVERT=1 >&2 >&-

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

SavePreviousCFG; #makes note of the config you chose for later

#blank or unblank (priority to unblank) but not both
if [[ "$UNBLANK" == "1" ]]; then
    Remote_CMD unblank $PI
    echo "Screen on $PI has been activated"'!'
elif [[ "$BLANK" == "1" ]]; then
    Remote_CMD blank $PI
    echo "Screen on $PI has been blanked"'!'
fi

#note omxplayer has preference in the case it is read in.
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
    
    echo -n "$APP "; if [ -z "$I_WANT_IT_NOW" ]; then 
    echo -n "set to run on reboot."; else
    echo -n "starting shortly.";fi

fi

if [[ "$KILL_MIDORI" == "1" ]]; then
    Remote_CMD killMidori "$PI"
    echo "Application Killed.."
elif [[ "$KILL_OMX" == "1" ]]; then
    Remote_CMD killOmx "$PI"
    echo "Application Killed.."
fi

if [ ! -z "$LIST_CONFIG" ]; then
    Remote_CMD list "$PI"
fi

if [[ "$REVERT" == "1" ]]; then
    Remote_CMD revert "$PI"
    echo "Reverted most recent changes."
fi

if [[ "$REBOOT" == "1" ]]; then
    Remote_CMD reboot "$PI"
    echo "System $PI will reboot now"'!'
fi

