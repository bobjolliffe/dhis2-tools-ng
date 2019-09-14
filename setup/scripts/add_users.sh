#! /usr/bin/env bash

USERKEYS=$(find ./users -iname *.pub)

for uk in $USERKEYS 
do
   U=$(basename -s .pub $uk)

   if [ ! $(id -u $U 2>>/dev/null) ]; 
   then 
     PASSWD=$(openssl rand -hex 12)
     sudo useradd -U -m -s /bin/bash -G sudo $U
     echo -e "$PASSWD\n$PASSWD" | passwd $U 2>>/dev/null
     echo $PASSWD > /home/$U/passwd.txt
     chown $U /home/$U/passwd.txt
     chmod 600 /home/$U/passwd.txt
     sudo -u $U mkdir /home/$U/.ssh
     sudo -u $U cp $uk /home/$U/.ssh/authorized_keys
     chmod 600 /home/$U/.ssh/authorized_keys
   else
     echo "User $U already exists"  
   fi
done
