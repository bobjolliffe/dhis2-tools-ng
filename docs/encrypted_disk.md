# Encrypting data disk for postgresql

(Note: these notes for setting up luks are deprecated.  They
should still be accurate, but its now much easier to use
native encryption on zfs filesyatem)

## Goal
In order to achieve encryption at rest we need to create an encryptedpartionion.  In our linode we have reserved /dev/sdd for this purpose.

We don't know if in the future our database is going to grow and we need to add extra disk space.  For this reason we should use lvm (or zfs) so that we can add additional disk volumes in the future.

The standard way of encrypting disks in linux is to use LUKS. It is possible to encrypt the underlying disk and add that as a physical volume for lvm (LVM over LUKS) or do it the other way (LUKS over LVM).  We will do the former.

## The steps
The following steps are required to prepare the disk:
1.  Encrypt the underlying disk
2.  Create an lvm physical volume (pv) with the encrypted disk
3.  Create an lvm volume group and add the pv. 
4.  Create an lvm volume within the volume group
5.  Format and fix permissions on the disk
6.  Make the disk available to the postgres container

Each of the steps are described in detail below:

### Encrypt the underlying disk

```
# echo -n "WeakP@ssword" | cryptsetup luksFormat /dev/sdc -
sudo cryptsetup -y luksFormat /dev/sdd
sudo cryptsetup luksOpen /dev/sdd cryptdata
```
The first command prepares the encrypted disk and asks for a pass phrase.  The
second command "opens" the disk (asking for the same pass phrase).  Following
this command, a new device is made available to the system at /dev/mapper/cryptdata.

We could go ahead and put a filesystem on this device and use it directly.  But
because we think we might need to add to it later, we will make it part of a
lvm volume group.

### Additional notes
28  echo -n "WeakP@ssword" | cryptsetup luksFormat /dev/sdc -
   30  cryptsetup luksOpen /dev/sdc data
   31  ls /dev/mapper/
   32  cryptsetup luksDump data
   34  cryptsetup luksDump /dev/sdc
   35  cryptsetup luksAddKey /dev/sdc
   36  cryptsetup luksDump /dev/sdc
   37  cryptsetup luksRemoveKey
   38  cryptsetup luksRemoveKey /dev/sdc
   39  cryptsetup luksDump /dev/sdc

### LVM setup
```
sudo pvcreate PV_cryptdata /dev/mapper/cryptdata
sudo vgcreate VG_cryptdata /dev/mapper/cryptdata
sudo lvcreate --name LV_cryptdata -l 100%FREE VG_crypt
```
This creates a volume group called VG_cryptdata which contains the (encrypted) physical volume.  
The lvcreate command creates a logical volume which uses 100% of the volume group space.

If in the future we need to expand the space we would just need to add the additional (encrypted) 
disk to the volume group and extend the logical volume within it.

### Preparing the disk
Now that we have our encrypted disk we need to prepare it for use by the postgres container.  This 
involves putting a filesystem on it and adjusting the ownership so that the root user in the container
is able to read and write to it.

```
sudo mkfs -t ext4 /dev/VG_cryptdata/cryptdata
mkdir tmp
sudo mount /dev/VG_cryptdata/cryptdata tmp
chown -R 1000000 tmp/*
sudo umount tmp
```
 
