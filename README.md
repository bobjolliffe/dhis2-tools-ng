# dhis2-tools-ng

Tools for setting up dhis2 on lxd.  A very short install guide.

Note that this guide is supplementary to the Implementation Guide.  Here we use that guide as a 
configuration reference, and implement those configurations into a set of automated tools for
installation and management.  It is not the intention here to repeat all the detailed explanation
that is provided there.

Note also that DHIS2 is quite a complex system requiring some experience of linux, web based systems, database management etc to manage sustainably and securely.  There are a number of organisations who provide hosting services as a business.  If you do not have the skills or the resources in-house, you might be better outsourcing to one of these.

This install guide describes a particular setup approach which is already used by a number of
country systems in production.  The main reason you might want to follow this approach would 
be if it is important for you to take advantage of (and contribute to) a community supported 
process.

## Prerequisites you need before you start:

1.  Your fully qualified domain name (FQDN), like `hmis.mygov.org`. Note this is just the name, not a URL like `https:\\hmis.mygov.org` This setup is designed for production use so it is assumed it will be using SSL/TLS which further assumes that you have a FQDN which will properly resolve to the public IP that you are exposing service on.  Do not proceed further until you have sorted this.

2.  Your timezone.  In order to see the list of available timezones type `timedatectl list-timezones`.  Make a note of your desired timezone.  Most likely you will want to also set the timezone on your host machine.  You can do this by typing `timedatectl set-timezone Africa/Dar_es_Salaam`.

3.  Make sure that your host OS is minimally and securely setup, with ufw firewall enabled (don't forget to allow your ssh port).  NOTE that the installation described below will fail if you have not enabled ufw on the host.  You can follow a useful guide to do the initial steps to secure your base system [here](docs/securing_base.md). 

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

`dhis2-deploy-war -l https://releases.dhis2.org/2.33/2.33.2/dhis.war hmis`

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
sudo lxc exec postgres -- psql -c 'select name,id from dataelement limit 5' hmis 
```
Note the "--" is necessary.  It tells lxc exec that everything following (including commandline switches like -c in this case) are to be interpreted as part of the remote command.

## Post install tasks

### Database
The system should now be working, but you will probably want to tune your database a little to
get the best performance from your available resources.  A good start would be to determine first what is the total amount of memory your machine has (see total memory after executing 'free -gh').  Let us proceed as though there is 32GB RAM in total.

Deciding how much RAM to deidicate to postgresql depends a little on how many DHIS2 instances you are likely to run, but assuming you will have a production instance and perhaps a small test instance, giving 16GB exclusively to postgresql is a reasonable start.  You can enforce that limit so that the postgresql container only sees 16GB RAM by typing:

`sudo lxc config set postgresql limits.memory 16GB'

If you run `free -gh` inside the postgresql container you will see that it no longer can see the full amount of RAM, but has been confined to 16GB.  (try `sudo lxc exec postgres -- free -gh`).

Then `sudo lxc exec postgres bash` to get to your postgres container.

The file where all your custom settings are made is called `/etc/postgresql/10/main/conf.d/dhispg.conf`.  The default contents of this file is shown below:

```
# Postgresql settings for DHIS2

# Adjust depending on number of DHIS2 instances and their pool size
# By default each instance requires up to 80 connections
# This might be different if you have set pool in dhis.conf
max_connections = 200

# Tune these according to your environment
# About 25% available RAM for postgres
# shared_buffers = 3GB

# Multiply by max_connections to know potentially how much RAM is required
# work_mem=20MB

# As much as you can reasonably afford.  Helps with index generation
# during the analytics generation task
# maintenance_work_mem=512MB

# Approx 80% of (Available RAM - maintenance_work_mem - max_connections*work_mem)
# effective_cache_size=8GB

# This setting is suitable for good SSD disk.  For slower spinning disk consider
# changing to 4
random_page_cost = 1.1

checkpoint_completion_target = 0.8
synchronous_commit = off
log_min_duration_statement = 300s
max_locks_per_transaction = 1024
```
The 4 settings that you should uncomment and give values to are `shared_buffers, work_mem, maintenance_work_mem` and `effective_cache_size`.  With 16GB of RAM, reasonable settings for these would be:
```
shared_buffers = 4GB
work_mem=20MB
maintenance_work_mem=1GB
effective_cache_size=11GB
```
Before applying these settings you should shutdown any running DHIS2 instances.  So, for example, back on the host:
```
sudo lxc stop covid19
sudo lxc restart postgresql
sudo lxc start covid19
```
Postgresql is an extremely configurable database with hundreds of configuration parameters.  This
brief installation guide only touches on the most important tunables. 

(TODO: install postgresql munin plugin)

### DHIS2 instances

When you install a dhis2 instance (with `dhis2-create-instance`), a lxc container is created with
a standard system installation of tomcat 9.  Whereas this is sufficient to run a dhis2 application
war file (see `dhis2-deploy-war` above), you will want to make some adjustments to the memory settings and perhaps other configuration tweaks.

#### File locations
The following are locations within the container that you will find common files for DHIS2 tweaking:
1.  /etc/default/tomcat9 - this is where environment variables such as JAVA_OPTs are kept 
2.  /etc/tomcat9/server.xml - you shouldn't need to do anything in here.  Unless you want to change the http pool size
3.  /opt/dhis2 - this is where your DHIS2_HOME is.  Most important file in there is dhis.conf.

Something which is quite different with tomcat9 on ubuntu is that it no longer uses catalina.out as its 
console log.  Instead it is logging these messages using the standard syslog mechanism.  So you
can find your tomcat messages in /var/log/syslog rather than catalina.out.  The dhis2-specific logs
can be found at /opt/dhis2/logs/.

#### Environment settings (/etc/default/tomcat9)
The main thing to set in here is the JAVA_OPTS.  Following our example, we have 16GB of RAM left,
so we might want to give 8GB to our covid19 instance:

`JAVA_OPTS="-Djava.awt.headless=true -XX:+UseG1GC  -Xmx8G -Xms8G -Djava.security.egd=file:/dev/./urandom"`

Change the 8G to whatever suits your environment.  For example a small test instance might run with only 2GB heap size.  We will discuss later in monitoring and troubleshooting how you know whether the setting is suitable for the load you are catering for.

The bit at the end (`-Djava.security.egd=file:/dev/./urandom`) can be important when running tomcat in virtual machines where it depends on a virtual source of randomness.  

#### DHIS2 (/opt/dhis2/dhis.conf)
The important parameters, for example to make the database connection work, will already have been
set in here.  The file contains a copy of all the possible configuration parameters (mostly commented out).  Refer to the implementation guide for a detailed explanation of each.

Three parameters you might consider uncommenting/changing:

1.  connection.pool.max_size - the default value of this is 80 which should be adequate for most systems.  For a small test system consider reducing this to, say 10.  In very rare instances, usually when there is some other problem in your database, you might need to increase this.  You need to ensure as you modify this that you stay within the limits of `max_connections` in postgresql configuration.
2.  analytics.cache.expiration - if you uncomment this and keep the default setting of 3600, it will cache the results of SQL analytics queries for an hour.  These can sometimes be a big load on your database so it is highly advisable to enable this. On large aggregate systems it can have a dramatic effect.
3.  system.session.timeout - this determines how long you can leave the application without being obliged to log back in again.  The default setting (1 hour) is probably too long for sensitive applications in clinical settings.  Something like 10 or 15 minutes might be more reasonable.

#### Monitoring agent
It is important to setup a monitoring agent on your DHIS2 instance.  If you have run the standard 
setup you will have installed a monitor called `munin`.  To enable detailed monitoring of your
tomcat application, you should run:

`sudo dhis2-tomcat-munin <instance_name> proxy`

to setup the agent.  (change <instance_name) to your instance, eg. hmis, covid19 ...

### Web proxy

