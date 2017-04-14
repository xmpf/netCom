set ns [new Simulator]

# αρχείο γραφικής αναπαράστασης :: nam
# open file with write permissions
set nf [open lab1.nam w]
$ns namtrace-all $nf

# αρχείο καταγραφής κίνησης
# open file with write permissions :: trace
set xf [open lab1.tr w]

proc record {} {
	global sink xf
	set ns [Simulator instance]
	set time 0.12
	set bw [$sink set bytes_]
	set now [$ns now]
	puts $xf "$now [expr ((($bw / $time) * 8) / 1000000)]"
	$sink set bytes_ 0
	$ns at [expr $now + $time] "record"
}

proc finish {} {
	global ns nf xf
	$ns flush-trace
	close $nf
	close $xf
	exit 0
}

# create new node with handle n0
set n0 [$ns node]
# create new node with handle n1
set n1 [$ns node]

$ns duplex-link $n0 $n1 4Mb 10ms DropTail

set agent0 [new Agent/UDP]
$agent0 set packetSize_ 1500
$ns attach-agent $n0 $agent0

set traffic0 [new Application/Traffic/CBR]
$traffic0 set packetSize_ 1500
$traffic0 set interval_ 0.01
$traffic0 attach-agent $agent0

set sink [new Agent/LossMonitor]
$ns attach-agent $n1 $sink
$ns connect $agent0 $sink

# simulator options
$ns at 0.0 "record"
$ns at 2.0 "$traffic0 start"
$ns at 10.0 "$traffic0 stop"
$ns at 12.0 "finish"

$ns run
