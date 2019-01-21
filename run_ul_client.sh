#!/bin/bash

if [ $# -lt 8 ]; then
	echo "Usage: $0 dest_ip core_number msg_rate_per_client payload_integers_number dest_base_port dest_ports_number time logfile"
	exit 1
fi

dest_ip=$1; shift
core_number=$1; shift
msg_rate_per_client=$1; shift
payload_integers_number=$1; shift
sockperf_header=$[14+2]
integer_size=4
msg_size=$[ $payload_integers_number * $integer_size + $sockperf_header]
dest_base_port=$1; shift
dest_ports_number=$1; shift
time=$1; shift
logfile=$1; shift


DIR='/home/maroun/BF_workspace/sockperf/ul_logs'


if [[ -f $DIR/config.txt ]]; then
	rm -f $DIR/config.txt
fi


for i in `seq 0 1 $[$dest_ports_number-1]`; do
	echo $dest_ip:$[$dest_base_port+$i] >> $DIR/config.txt
done
	

sudo taskset -c $core_number,$[$core_number+1] env LD_PRELOAD=/home/maroun/libvma/src/vma/.libs/libvma.so VMA_MTU=200 VMA_RING_ALLOCATION_LOGIC_RX=20 VMA_RING_ALLOCATION_LOGIC_TX=20 VMA_RX_POLL=1000 VMA_RX_UDP_POLL_OS_RATIO=0 VMA_SELECT_POLL_OS_RATIO=0 VMA_SELECT_POLL=2000000 VMA_THREAD_MODE=1 VMA_RX_POLL_YIELD=0 VMA_RX_NO_CSUM=1 VMA_NICA_ACCESS_MODE=0 $DIR/../sockperf ul -f $DIR/config.txt --dontwarmup --mps $msg_rate_per_client -m $msg_size -n $payload_integers_number -t $time --nonblocked --daemonize --full-log $logfile --reply-every 1 
