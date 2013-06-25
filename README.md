PiMan
=====

This is for remote raspberry pi managment.

    Usage: 
	./piman.sh 
	[ -b | -c [cmd] | -h | -km | -ko | -l | -m [url]
	| -mn [url] | -o [path] | -on [path] | -p [hostname] 
	| -p# | -p#-# | -p#,# | -pc  | -pcn | -r | -t | -u ] 

	Options:
	-b   | --blank	      Blank the monitor using dpms
	-c   | --cmd	      Pass a command to the machine, NOTE: use "" on multi word cmds
	-h   | --help         Show this help menu
	-km  | --kill-midori  Kills all midori processes
	-ko  | --kill-omx     Kills all omxplayer processes
	-l   | --list	      List the current configuration
	-m   | --midori       Use midori with the url, (either provided or default)
	-mn  | --midori-now   You want midori now, not later		    
	-o   | --omxplayer    Use Omxplayer with path, (either provided or default)
	-on  | --omx-now      You want omxplayer now!		    
	-p   | --pi 	      Host to control (use ALL for all) 
	-p#  | -p#-# | -p#,#  Where # is a host,#-# is a range
	-pc  | --prev-cfg     Reverse changes made last
	-pcn | --prev-cfg-now Reverse changes immediately
	-r   | --reboot       Apply the settings then reboot
	-t   | --tour	      Run the Tour Video then reset
	-u   | --unblank      Unblank the monitor using dpms


