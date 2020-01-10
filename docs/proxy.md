# Web reverse proxy setup

## General considerations
There are a couple of choices for a web proxy server, each of which have distinct
advantages and disadvantages.  In this guide we give example setups for apache2 (2.4)
and nginx.

Regardless of the choice of proxy, the following general principles apply:
1.  The host based firewall should be restricted appropriately
2.  Web servers should not be accessable via IP address.  A fully qualified domain name
(FQDN) is required for TLS/SSL setup so its use should be enforced.  Allowing access via
IP address leaves the host vulnerable to a wide variety of attackers who are constantly
scanning and testing IP addresses
3.  TLS/SSL is absolutely necessary for a DHIS2 application in production
4.  The organisation should maintain and apply a checklist of controls to ensure that a 
minimum standard of configuration is enforced throughout.  CIS publishes useful lists for 
apache2 and nginx which can be adopted or modified as required.
5.  

## SSL/TLS certificates
In general we
recommend using letsencrypt free certificates where it other options are difficult.  The 
type of difficulty often encountered include:
i.   buearocratic problems/delay in getting an *official* government certificate;
ii.  sanctions which prevent a country purchasing from US and EU companies; 
iii. difficulty obtaining or using credit cards in many jurisdictions.
The community has had good experience so far working with letsencrypt certificates.  Despite
being free, the quality of encryption offered is just as good as paid alternatives.
(are there any issues with android devices?)

A word of caution on wildcard certificates: there are a number of cases where a ministry of
health or NGO has purchased a wildcard certificate which is valid on all hosts within a particular 
domain.  For sensitive applications like DHIS2 we do not recommend using these.  In order to
work across a domain, the same private key needs to be installed on each server.  Effectively this 
implies that the certificate is only as strong as the weakest machine using the wildcard 
certificate.  This is an unnecessary risk, particularly where you have no control over the other
hosts using the certificate.