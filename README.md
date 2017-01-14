Vagrant - Kafka
=============

This is a Vagrant configuration to setup a partitioned Apache Zookeeper + Kafka installation. It is based on the Vagrant setup https://github.com/eucuepo/vagrant-kafka.


This configuration will start and provision three CentOS7/64-Bit VMs. All of the three host a zookeeper and a kafka node. The installation is based on JDK 8, Kafka 0.10.0.0 and Zookeeper 3.58.

Prerrequisites
-------------------------

* Vagrant (tested on 1.8.1)
* VirtualBox (tested on 5.1.10)

Setup
-------------------------

To start it up, just git clone this repo and execute ```vagrant up```. You can speed things up by downloading the required JDK and apache packages to the 'pkg' folder upfront. Otherwise provisioning will take a long time as it downloads all required dependencies for each node that is set up.

Kafka and Zookeeper will be installed in /opt/kafka and /opt/zookeeper accordingly. For both tools a system user is created. Both users share the 'kafka' group.

Here is the mapping of VMs to their private IPs:

| Name        | Address    |
|-------------|------------|
|zookeeper1   | 10.30.3.2  |
|zookeeper2   | 10.30.3.3  |
|zookeeper3   | 10.30.3.4  |

Zookeeper servers bind to port 2181. Kafka brokers bind to port 9092. 

Test
-------------------------

First test that all nodes are up ```vagrant status```. The result should be similar to this:

```
Current machine states:

zookeeper1                running (virtualbox)
zookeeper2                running (virtualbox)
zookeeper3                running (virtualbox)


This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run 'vagrant status NAME''.
```

Login to any host with e.g., ```vagrant ssh zookeeper1```. You will then be connected to the 'vagrant' user. To switch to the kafka user omit 

```
su - kafka
```

or 
```
su - zookeeper
```
respectivly. Password equals username in the standard setup.


### Zookeeper (ZK)

Kafka is using ZK for its coordination, bookkeeping, and configuration. To work with the ZK installation, log in on one of your clusters node and switch to the zookeeper user. As the bin folder of the zookeeper installation is set on the path you can directly type zookeeper commands without further switching the folder :

#### Open a ZK shell


```zkCli.sh``` 

connects to your local node of the cluster. To directly connect to a special node you can omit 
```zkCli.sh -server <ip>:<port>```

Inside the shell we can browse the zNodes similar to a Linux filesystem: 

```bash
ls /
[controller, controller_epoch, brokers, zookeeper, admin, isr_change_notification, consumers, config]

ls /brokers/topics
[t1, t2]

ls /brokers/ids
[1, 2, 3]
```

You can close the zookeeper shell by simply pressing Ctrl-C.

*Q: Which Zookeeper server is the leader?*

Here is a simple script that asks each server for its mode:

```bash
for i in 2 3 4; do
   echo "10.30.3.$i is a "$(echo status | nc 10.30.3.$i 2181 | grep ^Mode | awk '{print $2}')
done
```

### Kafka

Let's explore other ways to ingest data to Kafa from the command line. 

Login to any of the 6 nodes

```bash
vagrant ssh zookeeper1
```

Create a topic 

```bash
 /vagrant/scripts/create_topic.sh test-one
```

Send data to the Kafka topic

```bash
echo "Yet another line from stdin" | ./kafka_2.10-0.9.0.1/bin/kafka-console-producer.sh \
   --topic test-one --broker-list 10.30.3.10:9092,10.30.3.20:9092,10.30.3.30:9092
```

You can then test that the line was added by running the consumer

```bash
/vagrant/scripts/consumer.sh test-one
```

##### Add a continues stream of data

Running `vmstat` will periodically export stats about the VM you are attached to. 

```bash
>vmstat -a 1 -n 100

procs -----------memory---------- ---swap-- -----io---- --system-- -----cpu-----
 r  b   swpd   free  inact active   si   so    bi    bo   in   cs us sy id wa st
 0  0    960 113312 207368 130500    0    0    82   197  130  176  0  1 99  0  0
 0  0    960 113312 207368 130500    0    0     0     0   60   76  0  0 100  0  0
 0  0    960 113304 207368 130540    0    0     0     0   58   81  0  0 100  0  0
 0  0    960 113304 207368 130540    0    0     0     0   53   76  0  1 99  0  0
 0  0    960 113304 207368 130540    0    0     0     0   53   78  0  0 100  0  0
 0  0    960 113304 207368 130540    0    0     0    16   64   90  0  0 100  0  0
```

Redirecing this output to Kafka creates a basic form of a streaming producer.

```bash
vmstat -a 1 -n 100 | ./kafka_2.10-0.9.0.1/bin/kafka-console-producer.sh \
   --topic test-one --broker-list 10.30.3.10:9092,10.30.3.20:9092,10.30.3.30:9092 &
```

While the producer runs in the background you can start the consumer to see what happens

```bash
/vagrant/scripts/consumer.sh test-one
```

You should be seeing the output of `vmstat` in the consumer console. 

When you are all done, kill the consumer by `ctl-C`. The producer will terminate by itself after 100 seconds.


#### Offsets

The `create_topic.sh` script creates a topic with replication factor 3 and 1 number of partitions. 

Assuming you have completed the `vmstat` example above using topic `test-one`:

```bash
/vagrant/scripts/get-offset-info.sh test-one
test-one:0:102
```

There is one partition (id 0) and the last offset was 102 (from `vmstat`: 100 lines of reports + 2 header lines)
We asked Kafka for the last offset written so far using `--time -1` (as seen in [get-offset-info.sh](scripts/get-offset-info.sh)). You can change the time to `-2` to get the first offset. 
