# DHIS2 Installation on a Server Server

> *This guide is applicable to debian or Ubuntu Operating systems. Tested tow work on Ubuntu 18.04*

This is a brief guide to prepare your new server (Server Birthing process and cleanup) for DHIS2 installation.

* ## Server preparation and securing process

  At the end of this process, you new Ubuntu Server will be updated with all the required software libraries required for DHIS2 installation.
  
  * ### Update and upgrade your system
  
    As a root or sudo user, run the command below to update and install distribution upgrades. This will update all the apps in the existing repositories to the latest versions

     ```
     sudo apt-get update && sudo apt-get dist-upgrade
     ```
   * ### Secure your server
     
     Securing your new server is vital prior to setting up anything. To secure your server, first create a new sudo user and then block direct root access to the server.
     > Please note that you will be using the root user to accomplish this task
     
     As a root user, create a new user using the command below. Enter the corresponding answer as prompted during the process. `<username>` is the username of the new account you are creatinmg. so, change accordingly
     ```
     adduser <username>
     ```
     
     Next, add the new user to a sudo group. Doing this will allow the new user to execute tasks and manage the server as a root through `sudo` copmmand. Run the following command to achieve this.
     ```
     usermod -aG sudo <username>
     ```
     
     Confirm that the new user account can successfully login and execute tasks via `sudo` commands. This can be done by switching user `su` command and trying to execute tasks as sudo user. If all works well using sudo, then proceed to the next step otherwise, make sure that the new user can run as sudo user. Use the following commands to achieve this part.
     ```
     su <username>
     ```
     Try running sudo tasks e.g. view logs that using sudo as below
     ```
     sudo tail -f /var/log/syslog
     ```
     
     If all is working as described, we shall generate and add (if not already there) a SSH key to the server. If you dont have a SSH key, generate the key using the command below from the client computer. On windows, you could use any SSH client software on your laptop or use gitbash as below to generate key. Please replace the email address with a working email address. 
     > Remember to protect your key with a password that you wont forget
     ```
     ssh-keygen -t rsa -b 4096 -C "email@domain-name.com"
     ```
     After generating the SSH key, from your client computer, add the key using the command below. Please change the directory where the public key is and username and server-ip accordingly
     ```
     cat ~/.ssh/id_rsa.pub | ssh <username>@server-ip 'cat >> ~/.ssh/authorized_keys'
     ```
     Change the access permission to the authorized_keys using the command below
     ```
     sudo chmod 0600 ~/.ssh/authorized_keys
     ```
     
     Using your prefered SSHL client software, confirm that you can login using the SSH Key before proceding to the next section. 
     > Logout of the server and login back to the server using SSH key
     
     The next step is for us to prevent root access and password Authentication using SSH. This will allow us to only accept login using SSH keys for a user except root.
     
     As a sudo user, edit the SSH configuration file found normally at `/etc/ssh/sshd_config` using your favorite editor (e.g. `sudo vi /etc/ssh/sshd_config`) and change the following:
     - `PasswordAuthentication yes` to `PassswordAuthentication no`
     - `PermitRootLogin yes` to `PermitRootLogin no`
     
     Run the command below to effect the new changes for SSH server
     
     ```
     sudo systemctl restart sshd
     ```
     
     Verify that root login is no longer allowed and that `<username>` can login using public key and NOT using password
      > Logout of the server and login back to the server using SSH key for the  new `<username>` account. 
      > If you protected your key, you might be asked to provide the password for Key. Note that this password is not a normal system user password
     
     Next step then is to change the SSH default port 22 to any number below 1024. Numbers below 1024 are recommended because they will require root access to execute tasks.
     To change the port number, edit the SSH configuration file `/etc/ssh/sshd_config` and uncomment the `#Port 22` to `Port 22` then change the 22 to any number of your choice, e.g. 822. Your new Port will be `Port 822`. Save and exit.
     
     Run the command below to effect the new changes for SSH server
     
     ```
     sudo systemctl restart sshd
     ```
     
     verify that your new port works before proceding to the next stage. 
      > Logout of the server and login back to the server using SSH key and through new SSH port e.g. 822
     
     Next if everything works, enable firewall on the server and allow the new SSH port 822 using the commands below
     ```
     sudo ufw enable
     sudo ufw limit 822/tcp comment 'SSH Port rate limit' 
     ```
     Restart or reload firewall (ufw) and SSH services using the commands below
      ```
      sudo ufw disable
      sudo ufw enable
      ```
  * ### Install git on your server
  To be able to install dhis2-tools-ng on the server, install git using the command below
  ```
  sudo apt-get install git
  ```
  
  > At this point your server is ready for DHIS2 installation and made secure. Proceed to the next stage as described in the [README.md](./README.md)

     

