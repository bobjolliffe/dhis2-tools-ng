#dhis2-set-credential
Security of the servers and services is a priority. We need to set username and password credentials for the munin monitoring service and the Glowroot APM tool on each instance we have created to prevent unwanted users from accessing sensitive or critical data.
Credentials will be set once we install the monitor container or a DHIS2 instance with Glowroot APM or can be reset by the user later.

##Automatic execution
The dhis2-set-credential service will run once the monitor container is installed or when a DHIS2 instance with Glowroot APM is created. The user will be prompted to type in the desired password and otherwise it will be randomly generated.
```
SET <SERVICE> CREDENTIALS
====================
Do you want to add the password manually for the user admin in the service <SERVICE>? (If not, password will be generated randomly)
1) Yes
2) No
```

Password will be shown to the user
```
Credentials have been set
=================
Service: monitor (munin)
Username: admin
Password: XXXXX
```

##Manual execution
The user will be able to reset the password of a service by running the service script dhis2-set-credentials.
```
usage: dhis2-set-credential <SERVICE>
  Valid services are: <available services will be shown>
```

The user will be prompted to type in the desired password and otherwise it will be randomly generated and password will be shown to the user.
```
SET <SERVICE> CREDENTIALS
====================
Do you want to add the password manually for the user admin in the service <SERVICE>? (If not, password will be generated randomly)
1) Yes
2) No
```

```
Credentials have been set
=================
Instance: hmis
Service: hmis-glowroot
Username: admin
Password: XXXXX
```

If the user wants to reset a Glowroot APM password, he will be notified that in order to set the password, the instance will be restarted and he will be prompted for confirmation. Otherwise, the password will not be set.
```
Instance hmis will be restarted. Are you sure do you want to continue?
1) Yes
2) No
```

This procedure will only change the admin password. The rest of roles or users created will remain.
