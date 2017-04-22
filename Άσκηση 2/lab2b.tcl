set ns [new Simulator]
$ns rtproto DV
set nf [open lab2b.nam w]
$ns namtrace-all $nf

set f0 [open out0.tr w]
set f3 [open out3.tr w]

# --[Dynamic routing]--
Agent/rtProto/Direct set preference_ 200
$ns rtproto DV

# --[10 nodes topology]--
for {set i 0} {$i < 10} {incr i} {
  set n($i) [$ns node]
}
# -------------------------

for {set i 0} {$i < 8} {incr i} {
  $ns duplex-link $n($i) $n([expr ($i+1)%8]) 2Mb 30ms DropTail
}

$ns duplex-link $n(8) $n(3) 2Mb 10ms DropTail
$ns duplex-link $n(8) $n(4) 2Mb 10ms DropTail
$ns duplex-link $n(9) $n(4) 2Mb 10ms DropTail
$ns duplex-link $n(9) $n(6) 2Mb 30ms DropTail

# ---- [setting cost between links] --
for {set i 0} {$i < 8} {incr i} {
  $ns cost $n([expr $i]) $n([expr ($i+1)%8]) 3
  $ns cost $n([expr ($i+1)%8]) $n([expr $i]) 3
}
$ns cost $n(8) $n(3) 1
$ns cost $n(3) $n(8) 1

$ns cost $n(8) $n(4) 1
$ns cost $n(4) $n(8) 1

$ns cost $n(9) $n(4) 1
$ns cost $n(4) $n(9) 1

$ns cost $n(9) $n(6) 3
$ns cost $n(6) $n(9) 3


# --------[Procedures]---------------
proc record {} {
  global sink0 f0 sink3 f3
  set ns [Simulator instance]
  set time 0.02
  set bw0 [$sink0 set bytes_]
  set bw3 [$sink3 set bytes_]
  set now [$ns now]
  puts $f0 "$now [expr $bw0/$time*8/1000000]"
  puts $f3 "$now [expr $bw3/$time*8/1000000]"
  $sink0 set bytes_ 0
  $sink3 set bytes_ 0
  $ns at [expr $now+$time] "record"
}

proc finish {} {
  global ns nf f0 f3
  $ns flush-trace
  close $nf
  close $f0
  close $f3
  exit 0
}

# --[Node 0]--
set udp0 [new Agent/UDP]
#$udp0 set packetSize_   1500
$ns attach-agent $n(0)  $udp0
$udp0 set fid_          0
$ns color 0             red
set sink0 [new Agent/LossMonitor]
$ns attach-agent $n(0) $sink0

# --[Node 3]--
set udp3 [new Agent/UDP]
#$udp3 set packetSize_   1500
$ns attach-agent $n(3)  $udp3
$udp0 set fid_          3
$ns color 3             blue
set sink3 [new Agent/LossMonitor]
$ns attach-agent $n(3) $sink3

$ns connect $udp0 $sink3
$ns connect $udp3 $sink0

# ---[Traffic]--

## cbr0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_   1500
$cbr0 set interval_     0.025
$cbr0 attach-agent      $udp0

## expo3 [Exponential]
set expo3 [new Application/Traffic/Exponential]
$expo3 set packetSize_   1500
$expo3 set rate_         750k
$expo3 set interval_     0.016
$expo3 attach-agent      $udp3

# ---[Simulation options]--
$ns at 0.0 "record"
$ns at 0.4 "$cbr0 start"
$ns at 1.0 "$expo3 start"

#$ns rtmodel-at 2.2 down $n(1) $n(2)
#$ns rtmodel-at 3.2 up   $n(1) $n(2)

$ns at 24.5 "$expo3 stop"
$ns at 24.8 "$cbr0 stop"
$ns at 25.0 "finish"


# -- [run script] --
$ns run
