# Create a new simulator object
set ns [new Simulator]

$ns color 0 green
$ns color 1 yellow

# File I/O
set nf [open lab3.nam w]
$ns namtrace-all $nf

# -- trace file
set trf [open lab3.tr w]
$ns trace-all $trf

# -- Topology
for {set i 0} {$i < 4} {incr i} {
	set n($i) [$ns node]
}

## [5.5] change delay -> 102 msec
# --> Duplex link between nodes
# -----------------------------
for {set i 0} {$i < 4} {incr i} {
	$ns duplex-link $n($i) $n([expr ($i + 1) % 4]) 4Mb 102ms DropTail
	# -- Queue Limit
	$ns queue-limit $n($i) $n([expr ($i + 1) % 4]) 150
	$ns queue-limit $n([expr ($i + 1) % 4]) $n($i) 150
}


# -- Orientation
$ns duplex-link-op $n(0) $n(1) orient right
$ns duplex-link-op $n(1) $n(2) orient down
$ns duplex-link-op $n(2) $n(3) orient left
$ns duplex-link-op $n(3) $n(0) orient up

# -- Procedures
proc record {} {
	global sink0 trf nf
	set ns [Simulator instance]
	set time 0.2
  	set bw0 [$sink0 set bytes_]
  	set now [$ns now]
  	puts $trf "$now [expr $bw0/$time*8/1000000]"
  	$sink0 set bytes_ 0
  	$ns at [expr $now+$time] "record"
}

proc finish {} {
	global ns nf trf
	$ns flush-trace

	close $nf
	close $trf
	exit 0
}


# ------------[ GBN ]-------------------
## set up agent
set tcp0 [new Agent/TCP/Reno]
$tcp0 set packetSize_	2000
##### changed from 12 -> 17
$tcp0 set window_		12
## Disable modelling initial SYN/SYNACK exchange
$tcp0 set syn_			false
## initial size of congestion window
##### changed from 12 -> 17
$tcp0 set windowInit_	12
## define class ID
$tcp0 set fid_			0
$ns attach-agent $n(0) $tcp0
## set up sink
set sink0 [new Agent/TCPSink]
$ns attach-agent $n(3) $sink0
$ns connect $tcp0 $sink0
## set ftp client
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

# ------------[ S&W ]--------------------
set tcp1 [new Agent/TCP/Reno]
$tcp1 set packetSize_	2000
$tcp1 set window_ 		1
## disable syn/SYNACK
$tcp1 set syn_ 			false
$tcp1 set windowInit_ 	1
$tcp1 set fid_ 			1
$ns attach-agent $n(1) $tcp1

set sink1 [new Agent/TCPSink]
$ns attach-agent $n(2) $sink1
$ns connect $tcp1 $sink1

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
# ---------------------------------------


# ---- [ EVENTS ] ----------
$ns at 0.0 "record"

## -- Go Back N 
$ns at 0.0 "$n(0) label GBN_sender_3114702"
$ns at 0.0 "$n(3) label GBN_receiver_3114702"

## -- Stop n Wait
$ns at 0.0 "$n(1) label SW_sender_3114702"
$ns at 0.0 "$n(2) label SW_receiver_3114702"

$ns at 0.4 "$ftp0 produce 150"
$ns at 0.4 "$ftp1 produce 150"
$ns at 15.0 "finish"

$ns run
