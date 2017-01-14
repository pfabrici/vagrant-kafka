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

You can close the zookeeper shell by simply pressing Ctrl-C.

### Kafka
