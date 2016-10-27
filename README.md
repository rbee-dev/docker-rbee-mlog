# RBEE: MLog
### About
This image is for the [RBEE Project]; this part receives all data from an external benchmarking-software and inserts it into a Cassandra database.  
This image also contains an Elasticsearch-instance, which gets all the data from the Cassandra database by a script after the benchmark has been run.

### How to use
This image has been optimized for the Docker-native swarm available from Docker version 1.12, both Cassandra and Elasticsearch will be clustered when set up right.  
##### 1. Networking
Set up a custom network so the Docker-internal DNS resolution for service-discovery is available.
```sh
$ docker network create -d overlay rbee-mlog
```
When using any other networking driver than overlay, the hostname for the master-instance might have to be modified.  
Please refer to the available environment variables to change that name.
##### 2.1. Start a single instance
```sh
$ docker service create --name rbee-mlog-master --network rbee-mlog -p 9042:9042 -p 9200:9200 -p 9300:9300 rbee/mlog:<tag>
```
After a short moment the Cassandra database is reachable on port 9042 on any of the Docker-swarm hosts. Elasticsearch uses ports 9200 and 9300
##### 2.2 Start multiple instances
For clustering needs, we have to start two services.  
The _master_ will be used as central connection endpoint for both the Cassandra and Elasticsearch cluster. Otherwise the other instances won't be able to find each other.  
Since we'll be starting two services, only one can have the internal ports forwarded to the default external ports.
```sh
$ docker service create --name rbee-mlog-master --network rbee-mlog rbee/mlog:<tag>
$ docker service create --name rbee-mlog-slave --network rbee-mlog -p 9042:9042 -p 9200:9200 -p 9300:9300 rbee/mlog:<tag>
```
After a few moments, the rbee-mlog-slave instance should find the other for both Cassandra and Elasticsearch.  
Furthermore, the ports 9042, 9200 and 9300 on any Docker-swarm host will forward/load-balance to any of the running rbee-mlog-slave instances.

We included a script where you can see the status of the cluster for both Elasticsearch and Cassandra:
```sh
$ docker exec <instance-ID or instance-name> /scripts/get_running_instances.sh
ES_NODES: 2
ES_STATUS: green
CAS_UP: 2
CAS_DOWN: 0
CAS_UPNORMAL: 2
CAS_JOIN: 0
CAS_LEAVEMOVE: 0
```
This is a good way to see if all instances are up and clustered. This is important to know when scaling the _slave_-instances up. (For consistency's sake: Don't scale down or you might get some data loss!)

To scale the service, only the _rbee-mlog-slave_ may be upscaled by one instance at a time.  
Cassandra doesn't like multiple joining instances at once.
```sh
$ docker service scale rbee-mlog-slave=2
```
Now wait until the Cassandra-instance joined the cluster and is bootstrapped, you may increase the amount of instances again after that.
#### Environment variables
 * **RBEE_AUTOKILL** _(default: true)_  
If set to true: The container will kill itself completely if any of the services running fail after three restarts.
 * **RBEE_MASTER_HOST** _(default: tasks.rbee-mlog-master)_  
The DNS name for the master host. When using Docker 1.12 Swarm, the hostname without "_tasks._" will return the VirtualIP of the rbee-monitoring-master instance. The added "_tasks._" returns the actual containers IP address.

#### Elasticsearch fails
When Elasticsearch fails with the Error message

```ERROR: bootstrap checks failed
max virtual memory areas vm.max_map_count [65530] likely too low, increase to at least [262144]
```

You need to increase the maximum map count on the Docker host(s).  
See https://www.elastic.co/guide/en/elasticsearch/reference/5.0/vm-max-map-count.html and https://www.elastic.co/guide/en/elasticsearch/reference/5.0/_maximum_map_count_check.html

[RBEE Project]: <http://www.rbee.io>