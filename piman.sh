#! /bin/bash 

#Variable initialization
E_ARGERROR=2
REBOOT_ERROR=3
HOST_DNE_ERROR=4
APP_ERROR=5
REBOOT=""
SCRIPT_DIR=/home/pi/scripts
PI=""
APP=""
WEBPAGE=""
VIDEO_PATH=""
I_WANT_IT_NOW=""
INTERACTIVE=""
CMD=""
OPTIONS="APP,BLANK,CMD,KILL_MIDORI,KILL_OMX,LIST_CONFIG,REVERT,REBOOT,TOUR,UNBLANK"
VALID_ACTION=""
VALID_HOST=""
INVALID_INPUT=""

#Define Max Number of Pis in existence
NUMPIS=3
let ONELESSTHANMAX=$NUMPIS-1 #for communicating to a range of hosts

###functions###
#
#usage is: UsageDoc [exit code]
#
UsageDoc ()
{
    cat <<End-Of-Documentation
        
    
        Usage: 
        $0	
	[ -b | -c [cmd] | -h | -i | -km | -ko | -l | -m [url]
	| -mn [url] | -o [path] | -on [path] | -p [hostname] 
	| -p# | -p#-# | -p#,# | -pc  | -pcn | -r | -t | -u ] 

	Options:
	b   | -b    | --blank	      Blank the monitor using dpms
	c   | -c    | --cmd	      Pass a command to the machine
				        NOTE: use "" on multi word cmds
	h   | -h    | --help  	      Show this help menu
	i   | -i    | --interactive   This is a simple menu control
	km  | -km   | --kill-midori   Kills all midori processes
	ko  | -ko   | --kill-omx      Kills all omxplayer processes
	l   | -l    | --list	      List the current configuration
	m   | -m    | --midori        Use midori with the url 
			      		(either provided or default)
	mn  | -mn   | --midori-now    You want midori now, not later		    
	o   | -o    | --omxplayer     Use Omxplayer with path 
				        (either provided or default)
	on  | -on   | --omx-now       You want omxplayer now!		    
	p   | -p    | --pi 	      Host to control (use ALL for all) 
	-p# | -p#-# | -p#,#  	      Where # is a host,#-# is a range
	p#  | p#-#  | p#,#            Where # is a host,#-# is a range
	pc  | -pc   | --prev-cfg      Reverse changes made last
	pcn | -pcn  | --prev-cfg-now  Reverse changes immediately
	r   | -r    | --reboot        Apply the settings then reboot
	t   | -t    | --tour	      Run the Tour Video then reset
	u   | -u    | --unblank       Unblank the monitor using dpms


End-Of-Documentation
exit $1
}
#
#usage is: PrintMenu [menu desired] [optional/previous error]
#
PrintMenu ()
{
    clear 
    if [ ! -z "$2" ]; then
	#if there was an error say what was wrong, and if host provide host range
	if [[ "$1" == "host" ]]; then
	    HOST_RANGE=$(echo "1-$NUMPIS")
	    echo "You previous entered '$2' which is not valid (valid is p${HOST_RANGE})." 
	    echo "try again"'!'
	else
	    echo "You previous entered '$2' which is not a valid option, try again"'!'
	fi
    fi
    case $1 in
	action)
    		cat <<End-Of-Documentation
        
    
[ b | c [cmd] | km | ko | l | m [url] | mn [url] 
| o [path] | on [path] | pc  | pcn | r | t | u ] 

Options:
b   |   Blank the monitor using dpms
c   |   Pass a command to the machine
            NOTE: use "" on multi word cmds
km  |   Kills all midori processes
ko  |   Kills all omxplayer processes
l   |   List the current configuration
m   |   Use midori with the url 
            (either provided or default)
mn  |   You want midori now, not later		    
o   |   Use Omxplayer with path 
            (either provided or default)
on  |   You want omxplayer now!		    
pc  |   Reverse changes made last
pcn |   Reverse changes immediately
r   |   Apply the settings then reboot
t   |	 Run the Tour Video then reset
u   |   Unblank the monitor using dpms


End-Of-Documentation
echo -n "Select an action to perform(q to quit): " 

	;;
	host)
		cat <<End-Of-Documentation
        
[ p# | p#-# | p#,# ] 

Options:
p#  | p#-# | p#,#  Where # is a host,#-# is a range

End-Of-Documentation
echo -n "Which host would you like to manage(q to quit)? "
	;;
    esac

}
#
#Use ValidateAction [action or string of actions to validate]
#
ValidateAction ()
{
   # set -x
    DEALINGQUOTES=""

  for opt in $(echo "$1"); do
      #if this is true, the option is valid
      if [[ $(echo "$opt" | egrep "^-?[bclmoqQrtu]$|^--blank$|^--cmd$|^-?(km|ko|mn|on|pc|pcn)$|^--kill-midori$|^--kill-omx$|^--list$|^--midori$|^--midori-now$|^--omxplayer$|^--prev-cfg$|^--prev-cfg-now$|^--reboot$|^--unblank$|^https?.$|^/mnt/Share/$") ]];then
	  VALID_ACTION=1
      else
	  if [[ $(echo "$opt" | egrep "^\".*") || ! -z "$DEALINGQUOTES" ]]; then
	      if [[ $(echo "$opt" | egrep ".*\"$") ]]; then
		  #read the end quote
		  DEALINGQUOTES=""
	      else
                  #read begin quote or in between
	          DEALINGQUOTES=1
	      fi
	  else
	      VALID_ACTION=""
	      INVALID_INPUT="$opt"
	  fi
      fi
  done
  
  #set +x
  #sleep 15
}
#
#Use ValidateHost [host(s) to validate] 
#
ValidateHost ()
{
  for arg in $(echo "$1"); do
      #if this is true, the host is valid
      if [[ $(echo "$arg" | egrep "^-?p[1-$NUMPIS]$|^-?p[1-$ONELESSTHANMAX]-[2-$NUMPIS]$|^-?p[1-$NUMPIS],[1-$NUMPIS].*$|^-?(q|Q|pa)$") ]];then
	  VALID_HOST=1
	  INVALID_INPUT=""
      else
	  VALID_HOST=""
	  INVALID_INPUT="$arg"
      fi
  done
}
#
#use like: Remote_CMD [pseudo command] [host] [webpage/path]
#
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
	    CMD2RUN="xset -display :0 s reset && ${SCRIPT_DIR}/dpms_disable.sh && xrefresh -display :0 && rm /tmp/screenblanked > /dev/null"
	    #the xrefresh is due to a bug in omxplayer which sometimes blacks the screen.
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
	CMD2RUN="killall -q midori > /dev/null; if [[ "\$?" != "0" ]]; then cp ${SCRIPT_DIR}/previousConfig.bak ${SCRIPT_DIR}/previousConfig; fi"
	    ;;
	killOmx)
	    CMD2RUN="killall -q omxplayer.bin > /dev/null; if [[ "\$?" !=  "0" ]]; then cp ${SCRIPT_DIR}/previousConfig.bak ${SCRIPT_DIR}/previousConfig; fi && sleep 1 && xrefresh -display :0"
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
            #this allows for the revert command above to work
	    CMD2RUN="mv ${SCRIPT_DIR}/previousConfig ${SCRIPT_DIR}/previousConfig.bak && echo $3 > ${SCRIPT_DIR}/previousConfig"
	    ;;
	 list)
	    CMD2RUN="${SCRIPT_DIR}/AppMan.sh --list"
	    ;;
	 cmd)
	    CMD2RUN="$CMD2PASS"
	    #there is no filter, any command can be passed. Quotes on the multi-word ones.
	    ;;
	 tour)
            CMD2RUN="${SCRIPT_DIR}/AppMan.sh --tour --now"
            ;;	    
    esac
    #echo "Sending $1 command.."

    case $2 in
	[Aa][lL][lL] | [Aa])
	   #ssh keys should be configured already
	   #along with ~/.ssh/config or /etc/hosts
	   for (( i=1; i<=$NUMPIS; i++ )); do
	       ssh -n rpi${i} "$(echo -n $CMD2RUN) 2>&- &"
	       if [ "$?" -ne 0 ]; then
		   echo "rpi${i} is not responding"
	       fi
	   done
	   ;;
	[1-$ONELESSTHANMAX]-[2-$NUMPIS])
	   #this ^ allows for a dynamic range of hosts
	   #ssh keys should be configured already
	   #along with ~/.ssh/config or /etc/hosts
	   BOUND1=$(echo $2 | cut -f1 -d'-')
	   BOUND2=$(echo $2 | cut -f2 -d'-')

	   for (( i=$BOUND1; i<=$BOUND2; i++ )); do
	       ssh -n rpi${i} "$(echo -n $CMD2RUN) 2>&- &"
	       if [ "$?" -ne 0 ]; then
		   echo "rpi${i} is not responding"
	       fi
	   done
	   ;;
	[1-$NUMPIS],[1-$NUMPIS]*)
	   #talk to hosts as specified, respectively
	   for host in $(echo "$2" | tr ',' '\n'); do
	       ssh -n rpi${host} "$(echo -n $CMD2RUN) 2>&- &"
	       if [ "$?" -ne 0 ]; then
		   echo "rpi${i} is not responding"
	       fi
	   done
	   ;;
	[1-$NUMPIS])
	   ssh -n rpi${2} "$(echo -n $CMD2RUN) 2>&- &"
	   ;;
	*)
	   #troubleshooting, happens if function is called without host
	   echo "Host not specified...Who wrote this?"
	   ;;
    esac
   
}
#
#this function saves the new config options (in case of revert)
#it does not save revert, list, or command options
#
SavePreviousCFG ()
{
    
    PREVIOUS_CFG=""

    #Write to Previous config file unless it is revert time
    if [ -z  "$REVERT" -a -z "$LIST_CONFIG" -a -z "$CMD2PASS" ]; then     
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
	if [ ! -z "$PREVIOUS_CFG" ]; then
             Remote_CMD savePrevCFG "$PI" "$PREVIOUS_CFG"
	fi
    else
	sleep 0; #revert config do not save over prev cfg
    fi
}
###End Functions###

#saves the number of opts before processing since we use shift (the number
#after the case will always be 0 otherwise).
numopts=$#

#Option Processing
while [ "$1" != "" ]; do
  case $1 in
    -b | b | --blank)
	BLANK=1 >&2 >&-
	;;
    -c | c | --cmd)
        if [[ "$2" != "" && ! $( echo "$2" | grep -v ^-. | grep -v ^--. | grep "^p[1-9]") ]];then
            #only shift and store command if the next opt is dashless (i.e. not a switch)
	    shift #move positional params
	    CMD2PASS="$1"
	    CMD=1
	else
	    #become upset and exit with error no command passed
	    echo "Arg $1 requires a command to be passed to it."'!'
	    UsageDoc $E_ARGERROR
	fi
   	;; 
    -h | h | --help)
        UsageDoc 0 #function def above
       ;;
    -i  | i | --interactive)
    	INTERACTIVE=1 >&2 >&-
	;;
    -km | km | --kill-midori)
	KILL_MIDORI=1 >&2 >&-
	;;
    -ko | ko | --kill-omx)
	KILL_OMX=1 >&2 >&-
	;;
    -l  | l | --list)
        LIST_CONFIG=1 >&2 >&-
        ;;
    -m | m | -mn | mn | --midori | --midori-now)
       if [ -z "$APP" ]; then
	   #do not set app if it has already been set, someone is indecisive. 
	   APP="midori"
       else
	   #APP is already set, you can't have omx and midori...
	   echo "You have already set App to $APP, pick one App, not multiple."
	   exit $APP_ERROR
       fi

       if [[ $(echo "$1" | egrep "^-?mn$|^--midori-now$") ]]; then
	   I_WANT_IT_NOW=1 >&2 >&-
       fi

       if [[ "$2" != "" && $( echo "$2" | grep -v ^-. | grep -v ^--. | egrep -i "^http.//|^https.//") ]];then
           #shift and accept the path if provided
	   shift #move positional params
	   WEBPAGE=$1
       fi
       ;;
    -o | o | -on | on | --omxplayer | --omx-now)
       if [ -z "$APP" ]; then
	   #do not set app if it has already been set, someone is indecisive.
	   APP="omxplayer"
       else
	   #APP is already set, you can't have omx and midori...
	   echo "You have already set App to $APP, pick one App not multiple."
	   exit $APP_ERROR
       fi

       if [[ $(echo "$1" | egrep "^-?on$|^--omx-now$") ]]; then
	   I_WANT_IT_NOW=1 >&2 >&-
       fi

       if [[ "$2" != "" && $( echo "$2" | grep -v ^-. | grep -v ^--. | grep "^/") ]];then
           #shift and accept the path if provided
	   shift #move positional params
	   VIDEO_PATH=$1
       fi
       ;;
    -p | p | --pi | pi)   
       shift #move positional params
       if [[ "$1" != "" && $( echo "$1" | grep -v ^-. | grep -v ^--. ) ]];then
           PI=$1 #this works because we have shifted already
	   if [[ $(echo "$PI"| egrep "[1-$ONELESSTHANMAX]-[2-$NUMPIS]|[1-$NUMPIS],[1-$NUMPIS]") ]]; then
		#valid range or host,host format
		sleep 0 #you cannot have a comment without a command in an if statement
	   elif [[ ! $( echo "$PI" | egrep -i "^rpi[1-$NUMPIS]$|^[1-$NUMPIS]$|^[Aa][Ll][Ll]$" ) ]]; then
	       echo "Host does not exist (note Pi max number is $NUMPIS): $PI" && echo ""
	       exit $HOST_DNE_ERROR
	   else
	       #host does exist, filter off rpi if host is rpi1 ...
		if [[ "$PI" =~ "rpi" ]]; then
		    PI=$(echo "$PI" | cut -f2 -d'i')
		fi
	   fi
       else
	   echo "" && echo "Option -p or --pi requires an argument." && echo ""
	   UsageDoc $E_ARGERROR
	   exit
       fi
       ;;
    -p[0-$NUMPIS] | -p[1-$ONELESSTHANMAX]-[2-$NUMPIS] | -p[1-$NUMPIS],[1-$NUMPIS]* | -pa)
       #host is judged as valid if it passes the case condition.
       PI=$(echo "$1" | cut -f2 -d'p')
       ;;
    p[0-$NUMPIS] | p[1-$ONELESSTHANMAX]-[2-$NUMPIS] | p[1-$NUMPIS],[1-$NUMPIS]* | pa)
       #host is judged as valid if it passes the case condition.
       PI=$(echo "$1" | cut -f2 -d'p')
       ;;
    -pc | pc | -pcn | pcn | --prev-cfg | --prev-cfg-now)
       if [[ $(echo "$1" | egrep "^-?pcn$|-now$") ]]; then
	   I_WANT_IT_NOW=1 >&2 >&-
       fi

       REVERT=1 >&2 >&-
       ;;    
    -r | r | --reboot)
        REBOOT=1 >&2 >&-
       ;;
    -t | t | --tour)
    	TOUR=1 >&2 >&-
       ;;
    -u | u | --unblank)
	UNBLANK=1 >&2 >&-
       ;;
    -*)
       echo "Invalid option: $1. See usage below..." >&2
       UsageDoc $E_ARGERROR
       ;;
     *)
       echo "What is $1 supposed to be?"
       UsageDoc $E_ARGERROR
       ;;
  esac
  shift #move positional parameters
done

if [ -z "$PI" ]; then
    if [ -z "$INTERACTIVE" ];then
	#if someone forgot the host assume interactive
	INTERACTIVE=1
    fi
elif [ -z "$INTERACTIVE" ];then
    SOMEACTION=""
    for opt in $(echo "$OPTIONS" | tr ',' '\n'); do
	#if option is not empty build opt string
	if [ ! -z $(eval echo "\$$opt") ]; then
	    SOMEACTION=1
	fi
    done
    #if someone forgot the action assume interactive
    if [ -z "$SOMEACTION" ]; then
	INTERACTIVE=1
    fi
fi


if [ ! -z "$INTERACTIVE" -o "$numopts" -eq 0 ]; then
    #menu driven "gui" to run piman
    ACTIONS=""
    HOSTPI=""
    if [ -z "$BLANK" -a -z "$UNBLANK" -a -z "$APP" -a -z "$TOUR" -a -z "$REBOOT" -a -z "$LIST_CONFIG" -a -z "$KILL_OMX" -a -z "$KILL_MIDORI" -a -z "$CMD2PASS" ]; then
       #no actions requested, ask about it
       until [ ! -z "$INPUT" ]; do
           PrintMenu action "$INVALID_INPUT"
	   read INPUT
	   ValidateAction "$INPUT"
	   if [ -z "$VALID_ACTION" ]; then
	       INPUT=""
	   elif [[ $(echo "$INPUT" | egrep "^-?[qQ]$") ]]; then 
	       echo "quitting..."
	       exit 0
	   fi
       done
       ACTIONS="$INPUT"
    else
        #actions already requested, which are they
	for opt in $(echo "$OPTIONS" | tr ',' '\n'); do
	    #if option is not empty build opt string
	    if [ ! -z $(eval echo "\$$opt") ]; then
		case $opt in
		    APP)
		       if [[ "$APP" == "midori" ]]; then
			   if [ -z "$I_WANT_IT_NOW" ]; then
			       OPT="m"
			   else
			       OPT="mn"
			   fi
			   if [ ! -z "$WEBPAGE" ]; then
			       OPT=$(echo "$OPT $WEBPAGE")
			   fi
		       else
		           #it is omxplayer
			   if [ -z "$I_WANT_IT_NOW" ]; then
			       OPT="o"
			   else
			       OPT="on"
			   fi
			   if [ ! -z "$VIDEO_PATH" ]; then
			       OPT=$(echo "$OPT $VIDEO_PATH")
			   fi
		       fi

		    ;;
		    BLANK)
		    	OPT="b"
		    ;;
		    CMD)
		    	OPT="c \"$CMD2PASS\""
		    ;;
		    LIST_CONFIG)
		    	OPT="l"
		    ;;
		    KILL_MIDORI)
		    	OPT="km"
		    ;;
		    KILL_OMX)
		    	OPT="ko"
		    ;;
		    REBOOT)
		    	OPT="r"
		    ;;
		    REVERT)
		    	OPT="pc"
		    ;;
		    TOUR)
		    	OPT="t"
		    ;;
		    UNBLANK)
		    	OPT="u"
		    ;;
		    *)
		    	echo "Invalid option $opt"'!'
			exit 140
		    ;;
		esac
		ACTIONS=$(echo "$ACTIONS $OPT")
	    fi	
	done
    fi
    if [ -z "$PI" ]; then
       #no host specified
       until [ ! -z "$USERINPUT" ]; do
           PrintMenu host "$INVALID_INPUT"
	   read  USERINPUT
	   ValidateHost "$USERINPUT" 
	   if [ -z "$VALID_HOST" ]; then
	       USERINPUT=""
	   elif [[ $(echo "$USERINPUT" | egrep "^-?[qQ]$") ]]; then 
	       echo "quitting..."
	       exit 0
	   fi
       done
       HOSTPI="$USERINPUT"
    else
       #host and action specified.. 
       #must add the p back, stripped when read in
       HOSTPI="p$PI"
    fi 
    
    clear
    #execute requested command
    echo "running $(echo "$0" | sed -e 's|.*/||g') $ACTIONS $HOSTPI ..."
    eval $(echo "$0 $ACTIONS $HOSTPI")

    if [[ "$?" -eq "0" ]]; then
    	exit 0
    else
	exit 1 #something went wrong
    fi
fi



SavePreviousCFG; #makes note of the config you chose for later

#blank or unblank (priority to unblank) but not both
if [[ "$UNBLANK" == "1" ]]; then
    Remote_CMD unblank "$PI"
    echo "Screen has been activated on rpi${PI}"'!'
elif [[ "$BLANK" == "1" ]]; then
    Remote_CMD blank "$PI"
    echo "Screen has been blanked on rpi${PI}"'!'
fi

if [ ! -z "$APP" ]; then
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
    
    #print appropriate info
    echo -n "$APP "; if [ -z "$I_WANT_IT_NOW" ]; then 
    echo -n "set to run on reboot"; else
    echo -n "starting shortly";fi; echo -n " on rpi${PI}."
    echo ""
fi

#preference is given to kill midori, to change switch conditions and contents
#to evaluate and execute separately, make into two if statements
if [[ "$KILL_MIDORI" == "1" ]]; then
    Remote_CMD killMidori "$PI"
    echo "Kill command issued to rpi${PI} ..."
elif [[ "$KILL_OMX" == "1" ]]; then
    Remote_CMD killOmx "$PI"
    echo "Kill command issued to rpi${PI} ..."
fi

if [ ! -z "$LIST_CONFIG" ]; then
    Remote_CMD list "$PI"
fi

if [[ "$REVERT" == "1" ]]; then
    Remote_CMD revert "$PI"
    echo "Reverted most recent changes on rpi${PI}."
fi

if [ ! -z "$CMD2PASS" ]; then
    Remote_CMD cmd "$PI"
fi

if [ ! -z "$TOUR" ]; then
    Remote_CMD tour "$PI"
fi

if [[ "$REBOOT" == "1" ]]; then
    Remote_CMD reboot "$PI"
    echo "System(s) rpi${PI} will reboot now"'!'
fi

