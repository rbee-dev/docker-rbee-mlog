#!/bin/bash

elastic_health=$(curl -s localhost:9200/_cluster/health?pretty=true)
elastic_nodes=$(echo "$elastic_health" | awk '/number_of_nodes/ {print $3}' | sed -r 's/,//')
elastic_status=$(echo "$elastic_health" | awk '/status/ {print $3}' | sed -r 's/,//' | sed -r 's/\"//g')


echo "ES_NODES: $elastic_nodes"
echo "ES_STATUS: $elastic_status"

cassandra_status=$(nodetool status) 2> /dev/null

cassandra_up=$(echo "$cassandra_status" | awk '$1 ~ /^U[NLJM]/' | wc -l)
cassandra_down=$(echo "$cassandra_status" | awk '$1 ~ /^D[NLJM]/' | wc -l)
cassandra_upnormal=$(echo "$cassandra_status" | awk '$1 ~ /^UN/' | wc -l)
cassandra_join=$(echo "$cassandra_status" | awk '$1 ~ /^[DU]J/' | wc -l)
cassandra_leavemove=$(echo "$cassandra_status" | awk '$1 ~ /^[UD][LM]/' | wc -l)


echo "CAS_UP: $cassandra_up"
echo "CAS_DOWN: $cassandra_down"
echo "CAS_UPNORMAL: $cassandra_upnormal"
echo "CAS_JOIN: $cassandra_join"
echo "CAS_LEAVEMOVE: $cassandra_leavemove"
