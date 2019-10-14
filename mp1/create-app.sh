#!/bin/bash

REPOSITORY='davbera/Miniprojects.git'
CONTENT='davbera/mp1/www'

sudo apt-get update
sudo apt-get install -y apache2 git

#Get web content from github
cd /tmp
git clone git@github.com:$REPOSITORY 1>> /home/ubuntu/out.log 2>> /home/ubuntu/err.log

if [[ $? -eq 0 ]]; then
    temp=$(cp "./$CONTENT/*" /var/www/html 2>&1)
    if [[ $? -eq 0 ]]; then
        echo "The content was copied successfully" >> /home/ubuntu/out.log
    else
        echo "There was an error while copying web content. The error was:" >> /home/ubuntu/err.log
        echo $temp >> /home/ubuntu/err.log
    fi
else
    echo "There was an error while cloning git page" 1>> /home/ubuntu/out.log 2>> /home/ubuntu/err.log
fi

n=0
max=10
# Attach EBS volume to EC2 instance
while [ ! -e /dev/xvdf ] && [ $n -lt $max ]
do
    echo "Waiting for EBS volume to be attached to the instance. [Attempt $n]" 1>> /home/ubuntu/out.log 2>> /home/ubuntu/err.log
    n=$[$n+1]
    sleep 5;
done

if [ $n -eq $max ]; then
    echo "Maximum number of attempts ($max) reached. No device has been attached to the system" >> /home/ubuntu/out.log
else
    echo "EBS volume was attached to the instance" >> /home/ubuntu/out.log
    mkfs -t ext4 /dev/xvdf
    mkdir -p /mnt/storage-disk
    mount -t ext4 /dev/xvdf /mnt/storage-disk
    chown -R ubuntu:ubuntu /mnt/storage-disk/
fi