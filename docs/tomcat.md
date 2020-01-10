# Setting up tomcat8.5 and DHIS2

## Security Considerations
The web application is possibly the most vulnerable component of the system running in production.  Because of the large number of user interface components and libraries involved, the possibility of a vulnerability occurring in the application at some stage in the future can be quite high.  To mitigate the risk we should:

1.  Mininmize the likliehood of running a vulnerable war file by ensuring that it is kept up to date.  In general you should strive not to become more than 3 revisions behind the DHIS2 current release and make sure that patch releases are applied as they are released.
2.  Take precautions to ensure that if an attacker does succeed via the web application that the damage that can be done is as limited as possible.  This will typically involve restricting the access that the tomcat8 user has to the file system and access to the cron and at programs.
3.  Make sure the credentials used for the jdbc connection for the database are not shared by other instances.

## OS setup
The following assumes that you are working off an ubuntu 18.04 base system.  It is recommended that the environment is dedicated to tomcat and the DHIS2 application.  For example, it can be a dedicated virtual machine or a docker container or a lxd/lxc container.  In this guide we assumes an lxc container but the same principles apply to different environments.

The detailed steps for setting the base system is given in [OS setup](OS.md).  

You can ensure that tomcat8 user is not allowed to invoke crontab or atd by simply running:
```
echo tomcat8 >> /etc/cron.deny
echo tomcat8 >> /etc/at.deny
```

## Installing java and tomcat8 

The simplest way to setup the java environment is to use the openjdk runtime and install the tomcat server from system packages.  Note that currently DHIS2 does not work with java versions greater than 8, so it is best to install the runtime first to that a later version doesn't get pulled in as a tomcat dependency.  All that is required are the following commands:
```
apt-get install openjdk-8-jre-headless
apt-get install tomcat8
```

It is a good idea in production to ensure that the tomcat8 user is not able to deploy or modify the web applications.  There are a number of ways to ensure this, but the simplest is to run:

```
rm -rf /var/lib/tomcat8/webapps/*
chown -R root.root /var/lib/tomcat8/webapps
```

This has the effect of removing any pre-installed example pages and to make sure that only the root user can deploy webapps.  Note that you cannot then simply drop a war file into webapps.  As we will see in the section below, the war file needs to be unpacked into position.  

Besides that modification, the default permissions and settings of the ubuntu tomcat8 package are generally good.  You will need to modify the server.xml file to suit your environment.  I generally replace it rather than modify the default one.  An example is shown below:

```
<?xml version="1.0" encoding="utf-8"?>

<Server port="-1" >

  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />

  <Service name="Catalina">

    <Executor name="tomcatThreadPool" namePrefix="tomcat-http-" 
           maxThreads="100" minSpareThreads="10" />

    <Connector port="8080" protocol="HTTP/1.1"  proxyPort="443" scheme="https"  
        URIEncoding="UTF-8"
        executor="tomcatThreadPool" connectionTimeout="20000" relaxedQueryChars="[,]"/>

    <Engine name="Catalina" defaultHost="localhost">
      <Host name="localhost"  appBase="webapps" 
            unpackWARs="false" autoDeploy="false"
            xmlValidation="false" xmlNamespaceAware="false" >
        <!-- Mark HTTP as HTTPS forward from SSL termination at proxy -->
        <Valve className="org.apache.catalina.valves.RemoteIpValve"
            remoteIpHeader="x-forwarded-for"
            remoteIpProxiesHeader="x-forwarded-by"
            protocolHeader="x-forwarded-proto"
        />
      </Host>
    </Engine>
  </Service>
</Server>

``` 
Note that with the default install of tomcat8 on ubuntu 18.04, the following are the relevant directories for configuration and logs:

1.  **/etc/default/tomcat8** - this file is where you set JAVA_OPTS, CATALINA_OPTS and any other environment variables.
2.  **/etc/tomcat8 ** - this directory contains the files belonging to CATALINA_BASE (server.xml etc)
3.  **/var/log/tomcat8** - contains the main tomcat logs (catalina.out etc)
4.  **/var/lib/tomcat8/webapps** - should contain the unpacked war file for DHIS2 application as per instructions above
5.  **/opt/dhis2** - the DHIS2_HOME directory, containing dhis.conf, files, apps, custom logs etc.

## Installing DHIS2
There are four parts to installing DHIS2.  You need to create a database, you need to setup the DHIS2_HOME directory, you need to install a war file and you need to configure the reverse proxy server to forward requests to your upstream tomcat server.  Doing all this manually can be fiddly and error prone so it is best to use scripts to automate the creation of new instances.

### Creating a database
This needs to be done on the postgres server.  More instructions on that is available in  [Postgresql setup](postgres.md).   The important principles to bear in mind are:
1.  Each dhis2 instance should have a distinct postgresql role assigned which owns the database.  Having a generic dhis user can be dangerous practice if you have a number of instances connecting with the same user.  If one application is hacked all the databases can be vulnerable.
2.  The database role should have a long and preferably autogenerated password.
3.  Access to the database should be controlled as strictly as possible, both through pg_hba.conf and firewall settings. 

### Setting up DHIS2_HOME
DHIS2 will set its home directory to the value of the DHIS2_HOME evironment variable.  If it does not find this it will default (on linux) to use '/opt/dhis2'.  As we only one run tomcat instance within the container, the simplest option is then to create the /opt/dhis2 directory, owned by the tomcat8 user.

There are many options in the dhis.conf file and they are constantly being updated as new versions are released.  It is a good idea to start with the [dhis.conf reference](https://docs.dhis2.org/2.33/en/implementer/html/install_dhis2_configuration_reference.html)  for your DHIS2 version - note you should change the 2.33 in the URL to match your version).


### Installing a war file
To deploy an instance of a dhis.war file to an application called *hmis* you would have to do (as root):

```
rm -rf /var/lib/tomcat/webapps/*
mkdir /var/lib/tomcat/webapps/hmis
unzip dhis.war -d /var/lib/tomcat/webapps/hmis
```

As mentioned above, in practice you would run a deployment script on the host machine to push and unpack the war file into the container.

## Load balancer
Setting up tomcat8 in a load balanced configuration is not yet covered in this guide.  Please see [clustering tomcat](https://docs.dhis2.org/2.33/en/implementer/html/install_web_server_cluster_configuration.html) for more information.