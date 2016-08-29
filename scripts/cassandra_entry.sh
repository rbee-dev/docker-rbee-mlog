#!/bin/bash
set -e

#Get the seed-node's IP; Hostname is in ENV RBEE_MASTER_HOST
RBEE_MONITORING_MASTER="$(getent hosts $RBEE_MASTER_HOST | awk '{print $1}')"

if [ -z $RBEE_MONITORING_MASTER ]
then
	echo "WARNING: No host \"$RBEE_MASTER_HOST\" found, can't set seed node"
	exit 1
else

	# Get the (first) own IP that can reach the master server!
	# Docker might create multiple networks and we might end up taking the wrong one
	# IP is in the last field

	OWN_IP="$(ip route get $RBEE_MONITORING_MASTER | awk '/src/ {print $NF}')"
	echo "INFO: Using own IP $OWN_IP for default communication in cassandra"

	#Set Seed node
	sed -ri 's/(- seeds:).*/\1 '\"$RBEE_MONITORING_MASTER\"'/' "/etc/cassandra/cassandra.yaml"
	echo "INFO: Using $RBEE_MONITORING_MASTER as seed"

	# Set RPC Address, making it listen on all interfaces
	sed -ri 's/^(# )?('"rpc_address"':).*/\2 '"0.0.0.0"'/' "/etc/cassandra/cassandra.yaml"
	# Set RPC Boradcast Address; broadcast what RPC address is being used
	sed -ri 's/^(# )?('"broadcast_rpc_address"':).*/\2 '"$OWN_IP"'/' "/etc/cassandra/cassandra.yaml"
	# Set listen_address
	sed -ri 's/^(# )?('"listen_address"':).*/\2 '"$OWN_IP"'/' "/etc/cassandra/cassandra.yaml"
	# Start thrift
	sed -ri 's/^(# )?('"start_rpc"':).*/\2 '"true"'/' "/etc/cassandra/cassandra.yaml"

	sed -ri 's/^(# )?('"memtable_flush_writers"':).*/\2 '"1"'/' "/etc/cassandra/cassandra.yaml"
	sed -ri 's/^(# )?('"memtable_cleanup_threshold"':).*/\2 '"0.15"'/' "/etc/cassandra/cassandra.yaml"
	sed -ri 's/^(# )?('"memtable_allocation_type"':).*/\2 '"offheap_objects"'/' "/etc/cassandra/cassandra.yaml"
	sed -ri 's/^(# )?('"streaming_socket_timeout_in_ms"':).*/\2 '"3600000"'/' "/etc/cassandra/cassandra.yaml"
	sed -ri 's/^(# )?('"concurrent_reads"':).*/\2 '"128"'/' "/etc/cassandra/cassandra.yaml"
	sed -ri 's/^(# )?('"concurrent_writes"':).*/\2 '"128"'/' "/etc/cassandra/cassandra.yaml"


fi


# Run Cassandra; exec lets the process take over, so it is run directly without a shell script wrapped around.
exec /usr/sbin/cassandra -f