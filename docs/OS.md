# Operating system considerations

## Choices
The DHIS2 application components can run on a range of operating systems, including Microsoft
Windows, FreeBSD (and other BSDs) as well as various flavours of linux.  Most implementers choose
to run on some distribution of linux as the performance, security and reliability of the web
proxy and database tends to be better tested on linux.

The two most popular choices in production seem to be CentOS and Ubuntu.  Docker containers tend
to be built from micro-distributions such as Alpine Linux.  All of these environments are very
widely tested and so the choice tends to be one of personal choice and experience with the particular
environment.

This guide will describe an installation running ubuntu 18.04 on the host server together with a 
number of lxc containers also running ubuntu 18.04.  We will describe the process in a step by step
manner, but all of the steps below should be implemented as a simple shell script or an ansible playbook. 

## Ubuntu 18.04 setup

The following description applies to both the host machine and all the containers.  In each case we want
to ensure:
1.  that the package installation is the minimal required
2.  the ssh access is suitably configured

### Package update
When working off a fresh OS image it is important to ensure that all packages are updated. On ubuntu
run:
```
apt-get dist-update
apt-get dist-upgrade
```
You may wish to also setup unattended upgrades to ensure that security patches get applied 
automatically.  The tension here is between an automatic upgrade being applied which somehow
breaks the system vs a vital security patch being applied too late or never.  In general we 
recommend that unattended upgrades are configured unless you have a well functioning system for
alerting and manually updating as required.  It is also possible to *blacklist* certain packages,
eg. tomcat8 and openjdk, and thus ensure that OS upgrades are done automatically but updates to
these packages are applied manually.

In general I find that the risk of not applying unattended 

### Securing ssh

### Firewall setup 

## Mail and munin-node.  