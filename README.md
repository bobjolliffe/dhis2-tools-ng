# dhis2-tools-ng

Tools for setting up dhis2 on lxd

## Prerequisites you need before you start:

1.  Your fully qualified domain name (FQDN), like "hmis.mygov.org". This setup is designed for production use so it is assumed it will be using SSL/TLS which further assumes that you have a FQDN which will properly resolve to the public IP that you are exposing service on.  Do not proceed further until you have sorted this.

2.  Your timezone.  In order to see the list of available timezones type "timedatectl list-timezones".  Make a note of your desired timezone.

3.  Make sure that your host OS is minimally and securely setup, with ufw firewall enabled (don't forget to allow your ssh port)

## The short description:

1.  grab the install scripts from github:  `git clone https://github.com/bobjolliffe/dhis2-tools-ng.git`

2.  `cd dhis2-tools-ng/setup`

3.  `cp configs/containers.json.sample configs/containers.json`

4.  edit the top 3 lines of configs/containers.json to reflect your fqdn, email and tz:

	{
	  "fqdn":"li621-168.members.linode.com",
	  "email": "bob@dhis2.org",
	  "tz": "Africa/Dar_es_Salaam",
          ....
        }

(Resist the temptation of changing other things below these 3 lines for now.  Some of what appear as configurable defaults are still a bit hard-coded.  Will improve that soon)

5.  Run `sudo ./lxd_setup.sh`
(this could be a good time to make tea or coffee)

6.  Configure your proxy certificate by running `sudo fetchcertbot`

7.  Install the service scripts by running `sudo ./install_scripts.sh`
