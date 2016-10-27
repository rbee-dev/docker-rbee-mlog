#!/bin/bash

# Fix possible missing rights
chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/data

#Get the seed-node's IP; Hostname is in ENV RBEE_MASTER_HOST
RBEE_MONITORING_MASTER="$(getent hosts $RBEE_MASTER_HOST | awk '{print $1}')"

OWN_IP="$(ip route get $RBEE_MONITORING_MASTER | awk '/src/ {print $NF}')"
echo "INFO: Using own IP $OWN_IP for default communication in elasticsearch"

# Execute gosu in place of the shell, then have elasticsearch executed in place of gosu as user elasticsearch
exec gosu elasticsearch /usr/share/elasticsearch/bin/elasticsearch -E discovery.zen.ping.unicast.hosts=$RBEE_MASTER_HOST -E network.publish_host=$OWN_IP