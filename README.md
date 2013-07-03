PiMan
=====

This is for remote raspberry pi managment.

    Usage: 
	./piman.sh 
	[ -b | -c [cmd] | -h | -i | -km | -ko | -l | -m [url]
	| -mn [url] | -o [path] | -on [path] | -p [hostname] 
	| -p# | -p#-# | -p#,# | -pc  | -pcn | -r | -t | -u ] 

	Options:
	b   | -b    | --blank	      Blank the monitor using dpms
	c   | -c    | --cmd	      Pass a command to the machine, NOTE: use "" on multi word cmds
	h   | -h    | --help  	      Show this help menu
	i   | -i    | --interactive   This is a simple menu control
	km  | -km   | --kill-midori   Kills all midori processes
	ko  | -ko   | --kill-omx      Kills all omxplayer processes
	l   | -l    | --list	      List the current configuration
	m   | -m    | --midori        Use midori with the url, (either provided or default)
	mn  | -mn   | --midori-now    You want midori now, not later		    
	o   | -o    | --omxplayer     Use Omxplayer with path, (either provided or default)
	on  | -on   | --omx-now       You want omxplayer now!		    
	p   | -p    | --pi 	      Host to control (use ALL for all) 
	-p# | -p#-# | -p#,#  	      Where # is a host,#-# is a range
	p#  | p#-#  | p#,#            Where # is a host,#-# is a range
	pc  | -pc   | --prev-cfg      Reverse changes made last
	pcn | -pcn  | --prev-cfg-now  Reverse changes immediately
	r   | -r    | --reboot        Apply the settings then reboot
	t   | -t    | --tour	      Run the Tour Video then reset
	u   | -u    | --unblank       Unblank the monitor using dpms



