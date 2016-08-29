#! /bin/bash

# Get master IP
RBEE_MONITORING_MASTER="$(getent hosts $RBEE_MASTER_HOST | awk '{print $1}')"

OWN_IP="$(ip route get $RBEE_MONITORING_MASTER | awk '/src/ {print $NF}')"

# If we are master, check if 
if [[ $RBEE_MONITORING_MASTER == "$OWN_IP" ]]
then
	MIN_NODES=1
else
	MIN_NODES=2
fi

elastic_health="$(curl -s localhost:9200/_cluster/health?pretty=true)"
if [ $? -ne 0 ]
then
	echo "ES DOWN"
else
	elastic_nodes=$(echo "$elastic_health" | awk '/number_of_nodes/ {print $3}' | sed -r 's/,//')

	if [ $elastic_nodes -ge $MIN_NODES ]
	then
		echo "ES UP"
	else
		echo "ES LOW"
	fi
fi

cas="$(nodetool status 2> /dev/null)" 
if [ $? -ne 0 ]
then
	echo "CAS DOWN"
	exit 0
fi

cas_stat=$(echo "$cas" | grep $OWN_IP | awk '{print $1}') 

if [[ $cas_stat == D* ]]
then
	echo "CAS DOWN"
else
	if [[ $cas_stat == *N ]]
	then
		echo "CAS UP"
	elif [[ $cas_stat == *J ]]
	then
		echo "CAS JOIN"
	else
		echo "CAS OTHER"
	fi
fi
