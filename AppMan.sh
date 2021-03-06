#! /bin/bash

#initialization and info gathering
SCRIPT_DIR=/home/pi/scripts
CURRENT_APP=$( grep -v '^#' ${SCRIPT_DIR}/app2start | grep -m1 .. | cut -f1 -d' ' )
CURRENT_URL=$( grep -v '^#' ${SCRIPT_DIR}/homepage | grep -m1 .. )
CURRENT_PATH=$( grep -v '^#' ${SCRIPT_DIR}/video2play | grep -m1 .. )

#this function displays the help and exits appropriately
UsageDoc ()
{
    cat <<End-Of-Documentation
        
    
        Usage: 
	$0 
	[ -a [app name] | -h | -l | -n | -p [path/url] | -r ] 

	Options:
	-a | --app	   The app to start on reboot
	-h | --help        Show this help menu
	-l | --list	   List the current configuration
	-n | --now	   I want it all, and I want it now!
	-p | --path 	   The desired path or url to be changed
	-r | --revert	   Revert to previous configuration
	-t | --tour	   Tour video and then revert


End-Of-Documentation
exit $1
}

#this function unblanks the screen, needed due to omxplayer bug
UNBLANK_NOW ()
{
	if [ -f /tmp/screenblanked ]; then
 	   xset -display :0 s reset && ${SCRIPT_DIR}/dpms_disable.sh #unblank	      
	   rm /tmp/screenblanked
	   xrefresh -display :0
	fi
}

#record number of opts before processing, after case it would be 0
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
	   UsageDoc 4 #exit 4 for app error
	   exit
        fi
	;;
    -h | --help)
        UsageDoc 0 #function def above
       ;;
    -l | --list)
	LIST_CONFIG=1 >&2 >&-
	;;
    -n | --now)
	I_WANT_IT_NOW=1 >&2 >&-
       ;;
    -p | --path)   
        shift #move positional params
        if [[ "$1" != "" && $( echo "$1" | grep -v ^-. | grep -v ^--. ) ]]; then
           DESIRED_PATH=$1
	else
	   echo "" && echo "Option -p or --path requires an argument." && echo ""
	   UsageDoc 2 #exit 2 path error
	   exit
        fi
       ;;
    -r | --revert)
       REVERT=1 >&2 >&-
       ;;
    -t | --tour)
       TOUR=1 >&2 >&-
       ;;
    -*)
       echo "Invalid option: -$1. See usage below..." >&2
       UsageDoc $E_ARGERROR
       ;;
     *)
       UsageDoc $E_ARGERROR
  esac
  shift #move positional parameters
done

if [ "$numopts" -eq 0 ]; then
   #NoArgs
   UsageDoc $E_ARGERROR
elif [ -z "$DESIRED_APP" -a -z "$REVERT" -a -z "$LIST_CONFIG" -a -z "$TOUR" ]; then
    echo "You must supply an app to modify.."
    UsageDoc 3 #exit 3 app error
fi

#as long as we are not reverting, listing or going into tour mode
if [ -z "$REVERT" -a -z "$LIST_CONFIG" -a -z "$TOUR" ]; then
   if [[ "$CURRENT_APP" != "$DESIRED_APP" ]]; then
       #change to the desired app (which must already be in the app2start file)
       sed --in-place=.bak -e "s/\(^${CURRENT_APP}\)/#${CURRENT_APP}/g;s/\(^#${DESIRED_APP}\)/${DESIRED_APP}/g;" ${SCRIPT_DIR}/app2start
       echo "Desired App has been set.."
   fi

   #if there is a path/url to change then do so
    if [ ! -z "$DESIRED_PATH" ]; then
        if [[ "$DESIRED_APP" == "omxplayer" && "$TOUR" == "" ]]; then
            if [[ "$CURRENT_PATH" != "$DESIRED_PATH" ]]; then
	        #change the path in video2play (assumes all other paths are commented out)
	        sed --in-place=.bak -e "s|\(^${CURRENT_PATH}\)|#${CURRENT_PATH}|g;" ${SCRIPT_DIR}/video2play
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
elif [ ! -z "$REVERT" ]; then
    #revert settings
    if [ ! $(egrep -i '^blank$|^unblank$' ${SCRIPT_DIR}/previousConfig) ];then
	for switch in $(cat ${SCRIPT_DIR}/previousConfig); do
	   if [ ! $(echo "$switch" | grep -i blank) ]; then
	      case $switch in
		  midori)
		      APP="midori"
		      #swap with .bak cfg since that was the previous
		      mv ${SCRIPT_DIR}/app2start ${SCRIPT_DIR}/app2start.tmp
		      mv ${SCRIPT_DIR}/app2start.bak ${SCRIPT_DIR}/app2start #revert
		      mv ${SCRIPT_DIR}/app2start.tmp ${SCRIPT_DIR}/app2start.bak #back up reversion
		      ;;
		  omxplayer)
		      APP="omxplayer"
		      #swap with the .bak cfg
		      mv ${SCRIPT_DIR}/app2start ${SCRIPT_DIR}/app2start.tmp
		      mv ${SCRIPT_DIR}/app2start.bak ${SCRIPT_DIR}/app2start #revert
		      mv ${SCRIPT_DIR}/app2start.tmp ${SCRIPT_DIR}/app2start.bak #back up reversion
		      ;;
		  killMidori)
		      #restart midori which is already set to run
		      I_WANT_IT_NOW=1
		      ;;
		  killOmx)
		      #restart omxplayer which is already set to run
		      I_WANT_IT_NOW=1
		      ;;
		  path)
		      #determine which path needs reverted and do it.
		      if [[ "$APP" == "midori" ]]; then
			  mv ${SCRIPT_DIR}/homepage ${SCRIPT_DIR}/homepage.tmp
		          mv ${SCRIPT_DIR}/homepage.bak ${SCRIPT_DIR}/homepage #revert
		          mv ${SCRIPT_DIR}/homepage.tmp ${SCRIPT_DIR}/homepage.bak #back up reversion
		      else
			  mv ${SCRIPT_DIR}/video2play ${SCRIPT_DIR}/video2play.tmp
		          mv ${SCRIPT_DIR}/video2play.bak ${SCRIPT_DIR}/video2play #revert
		          mv ${SCRIPT_DIR}/video2play.tmp ${SCRIPT_DIR}/video2play.bak #back up reversion

		      fi
		      ;;
		  now)
		      #revert changes now because the previous command was replaced with 'now'
		      I_WANT_IT_NOW=1
		      ;;
	      esac
	  else
	      UNBLANK_NOW; #if there was a reference to blank, then unblank
	  fi 
       done
   else
       if [ $(grep -i "^blank$" ${SCRIPT_DIR}/previousConfig) ]; then
	   UNBLANK_NOW; #equivalent of using -- piman -u
       else
	   #blank -- equivalent of -- piman -b
	   sleep 1 && xset -display :0 s blank && xset -display :0 dpms force off
	   touch /tmp/screenblanked 
       fi
   fi       
fi

if [ ! -z "$I_WANT_IT_NOW" ]; then
    #we want it NOW
    if [ -z "$TOUR" ]; then
	#it is okay to kill apps
      	if [[ "$CURRENT_APP" == "midori" ]]; then
            killall -q midori > /dev/null 
        else
            killall -q omxplayer.bin > /dev/null
            xrefresh -display :0
        fi
        UNBLANK_NOW; 
        #run the desired app now
        eval nohup $(grep -v '^#' /home/pi/scripts/app2start | grep -m1 ..) &
        echo "App switching completed."
    else
	UNBLANK_NOW;
	
	#run omx over the browser without killing the browser
	#note command and path in tourVideo since it is static
	eval nohup $(grep -v '^#' /home/pi/scripts/tourVideo | grep -m1 ..) &
	
	#comment out from the echo below to the next one to avoid having the
	#ssh connection kept open to let you know when the tour vid is over.
	echo "Tour Video Began"
	sleep 3 #if we do not sleep, we check for the process before it begins
	while [[ $(ps aux | grep -i omx | grep -v grep) ]]; do
	    sleep 5;
	done
	echo "Tour Video finished, returning to Midori"
	
	xrefresh -display :0 #fixes blank screen omx bug
    fi
fi

if [ ! -z "$LIST_CONFIG" ]; then
    #Bring me that Medallion, everyone loves Pirates of the Caribbean
    echo ""
    echo "/*************************/"
    echo "Config for $HOSTNAME:"
    echo "Uptime: $(uptime | cut -f1 -d',' | cut -f2 -d'p' )"
    echo "App: $CURRENT_APP"
    echo "Webpage: $CURRENT_URL"
    echo "Video: $CURRENT_PATH"
    if [ -f "/tmp/screenblanked" ];then
	echo "Screen is: blank"
    else
	echo "Screen is: not blank"
    fi
    #running this once is better than twice below saves a half second generally
    runningApps=$(ps aux)

    if [[ $(echo "$runningApps" | grep -i omxplayer | grep -v grep) ]]; then
	echo "Running: omxplayer"
    fi
    if [[ $(echo "$runningApps" | grep -i midori | grep -v grep) ]]; then
	echo "Running: midori"
    fi
    echo "Most Recent CMD(s): $(cat ${SCRIPT_DIR}/previousConfig) "
    echo "/*************************/"
    echo ""
fi

