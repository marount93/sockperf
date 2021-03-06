#!/bin/bash

if [ $# -lt 8 ]; then
	echo "Usage: $0 dest_ip ips_number cores_number msg_rate_per_client number_of_integers_in_payload dest_base_port dest_ports_number time"
	exit 1
fi

MY_PATH="/home/maroun/BF_workspace/sockperf"

dest_ip=$1; shift
number_of_hosts=$1; shift
cores_number=$1; shift
msg_rate_per_client=$1; shift
payload_integers_number=$1; shift
sockperf_header=$[14+2]
integer_size=4
msg_size=$[$payload_integers_number * $integer_size + $sockperf_header]
dest_base_port=$1; shift
dest_ports_number=$1; shift
time=$1; shift


if [[ -f $MY_PATH/config.txt ]]; then
	rm -f $MY_PATH/config.txt
fi

for h in `seq 0 1 $[$number_of_hosts - 1]` ; do
	for i in `seq 0 1 $[$dest_ports_number-1]`; do
		ip_base=`echo $dest_ip | cut -d"." -f1-3`
		offset=`echo $dest_ip | cut -d"." -f4`
        ip_offset=$[$offset+$h]
		echo $ip_base $ip_offset
		ip="$ip_base"."$ip_offset"
		echo $ip:$[$dest_base_port+$i] >> $MY_PATH/config.txt
	done
done
	

for i in `seq 0 1 $[$cores_number-1]`; do taskset -c $i sudo env LD_PRELOAD=/home/maroun/libvma/src/vma/.libs/libvma.so VMA_MTU=200 VMA_RING_ALLOCATION_LOGIC_RX=20 VMA_RING_ALLOCATION_LOGIC_TX=20 VMA_RX_POLL=1000 VMA_RX_UDP_POLL_OS_RATIO=0 VMA_SELECT_POLL_OS_RATIO=0 VMA_SELECT_POLL=2000000 VMA_THREAD_MODE=1 VMA_RX_POLL_YIELD=0 VMA_RX_NO_CSUM=1 VMA_NICA_ACCESS_MODE=0 $MY_PATH/sockperf tp -f $MY_PATH/config.txt --dontwarmup -m $msg_size --mps $msg_rate_per_client -t $time -n $payload_integers_number --nonblocked --daemonize; done
