# dhis2-tools-ng

Tools for setting up dhis2 on lxd.  A very short install guide.

## Prerequisites you need before you start:

1.  Your fully qualified domain name (FQDN), like `hmis.mygov.org`. Note this is just the name, not a URL like `https:\\hmis.mygov.org` This setup is designed for production use so it is assumed it will be using SSL/TLS which further assumes that you have a FQDN which will properly resolve to the public IP that you are exposing service on.  Do not proceed further until you have sorted this.

2.  Your timezone.  In order to see the list of available timezones type `timedatectl list-timezones`.  Make a note of your desired timezone.  Most likely you will want to also set the timezone on your host machine.  You can do this by typing `timedatectl set-timezone Africa/Dar_es_Salaam`.

3.  Make sure that your host OS is minimally and securely setup, with ufw firewall enabled (don't forget to allow your ssh port)

## The install:

The steps outined below will take a bare server which is accessible to the internet via a public IP, and configure all the infrastructure required to create and maintain DHIS2 instances.

1.  grab the install scripts from github:  `git clone https://github.com/bobjolliffe/dhis2-tools-ng.git`

2.  `cd dhis2-tools-ng/setup`

3.  `cp configs/containers.json.sample configs/containers.json`

4.  edit the top 3 lines of configs/containers.json to reflect your fqdn, email and tz:

	{
	  "fqdn":"li621-168.members.linode.com",
	  "email": "bob@dhis2.org",
          "environment": {
            "TZ": "Africa/Dar_es_Salaam"
        },
          ....

(Resist the temptation of changing other things below these 3 lines for now.  Some of what appear as configurable defaults are still a bit hard-coded.  Will improve that soon)

5.  Run `sudo ./lxd_setup.sh`
(this could be a good time to make tea or coffee .. it will take some minutes)

6.  Install the service scripts by running `sudo ./install_scripts.sh`

At this point your proxy, database and monitor servers should be up and running.  You should be able to see them when you type `sudo lxc list`:
```
+----------+---------+---------------------+------+------------+-----------+
|   NAME   |  STATE  |        IPV4         | IPV6 |    TYPE    | SNAPSHOTS |
+----------+---------+---------------------+------+------------+-----------+
| monitor  | RUNNING | 192.168.0.30 (eth0) |      | PERSISTENT | 0         |
+----------+---------+---------------------+------+------------+-----------+
| postgres | RUNNING | 192.168.0.20 (eth0) |      | PERSISTENT | 0         |
+----------+---------+---------------------+------+------------+-----------+
| proxy    | RUNNING | 192.168.0.2 (eth0)  |      | PERSISTENT | 0         |
+----------+---------+---------------------+------+------------+-----------+
```
Note the IP addresses of the containers.  When we install DHIS2 instances, each instance will also run in its own container and will require its own IP address.  By convention we suggest creating containers starting at 192.168.0.10 through to 192.168.0.19.  If you need (and have resources) for more than 10, then you might start giving them different IPs.

You are now ready to start installing DHIS2 instances.

## Installing DHIS2 instances

1.  To create an instance you need to specify the name of the instance, the IP and the name of the database container (this is necessary as you might have more than one database container). For example to create an instance called hmis: 

`sudo dhis2-create-instance hmis 192.168.0.10 postgres`

To create another instance called staging:

`sudo dhis2-create-instance staging 192.168.0.11 postgres`

2.  Deploy a DHIS2 war file to your new instance:

`dhis2-deploy-war -l https://releases.dhis2.org/2.33/2.33.2/dhis.war`

3.  Browse to your new instance at `https://<your_hostname>/hmis`

## Working with instances

Now that you are up and running you can start doing some basic activities.

### Stopping, starting and restarting

Because each DHIS2 instance is running tomcat9 in its own container, the simplest way to do these operations is to just act directly on the lxc container:

```
sudo lxc stop hmis
sudo lxc stop staging
sudo lxc start hmis
sudo lxc restart staging
```

### Executing commands inside containers

Sometimes you might want to execute commands inside the container.  So for example if you wanted to edit the server.xml inside the staging container you might do:

```
bob@localhost:$ sudo lxc exec staging bash
root@staging:~# vi /etc/tomcat9/server.xml
root@staging:~# exit
```
Executing bash like this lands you at an interactive prompt.  This can be useful, but is not always what you want.  For example you might want to execute a query directly on the database like:

```
sudo lxc exec postgres -- psql -c 'select name,id from dataelement limit 5' 
```
Note the "--" is necessary.  It tells lxc exec that everything following (including commandline switches like -c in this case) are to be interpreted as part of the remote command.






