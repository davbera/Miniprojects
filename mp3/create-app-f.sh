#!/bin/bash
#Script for frontend instances
GITPAGE='illinoistech-itm/dgalanberasaluce.git'
CONTENT='dgalanberasaluce/itmo-544/mp3/frontend'
WARFILE='mp3.war'

#Variables updated dinamycally by create-env.sh
RDS_USERNAME=
RDS_PASSWORD=
RDS_DB_NAME=
RDS_PORT=
RDS_HOSTNAME=
BUCKET_NAME=
BUCKET_ORIG_IMAGE_FOLDER=
BUCKET_DEST_IMAGE_FOLDER=
QUEUE_NAME=
RDS_PORT_READ=
RDS_HOSTNAME_READ=

echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64/" >> /etc/profile
echo "export PATH=$JAVA_HOME/bin:$PATH" >> /etc/profile 
echo "export RDS_USERNAME=$RDS_USERNAME" >> /etc/profile
echo "export RDS_PASSWORD=$RDS_PASSWORD" >> /etc/profile
echo "export RDS_DB_NAME=$RDS_DB_NAME" >> /etc/profile
echo "export RDS_PORT=$RDS_PORT" >> /etc/profile
echo "export RDS_HOSTNAME=$RDS_HOSTNAME" >> /etc/profile
echo "export BUCKET_NAME=$BUCKET_NAME" >> /etc/profile
echo "export BUCKET_ORIG_IMAGE_FOLDER=$BUCKET_ORIG_IMAGE_FOLDER" >> /etc/profile
echo "export BUCKET_DEST_IMAGE_FOLDER=$BUCKET_DEST_IMAGE_FOLDER" >> /etc/profile
echo "export QUEUE_NAME=$QUEUE_NAME" >> /etc/profile
echo "export RDS_PORT_READ=$RDS_PORT_READ" >> /etc/profile
echo "export RDS_HOSTNAME_READ=$RDS_HOSTNAME_READ" >> /etc/profile

export RDS_USERNAME=$RDS_USERNAME
export RDS_PASSWORD=$RDS_PASSWORD
export RDS_DB_NAME=$RDS_DB_NAME
export RDS_PORT=$RDS_PORT
export RDS_HOSTNAME=$RDS_HOSTNAME
export BUCKET_NAME=$BUCKET_NAME
export BUCKET_ORIG_IMAGE_FOLDER=$BUCKET_ORIG_IMAGE_FOLDER
export BUCKET_DEST_IMAGE_FOLDER=$BUCKET_DEST_IMAGE_FOLDER
export QUEUE_NAME=$QUEUE_NAME
export RDS_PORT_READ=$RDS_PORT_READ
export RDS_HOSTNAME_READ=$RDS_HOSTNAME_READ

sudo apt-get update
sudo apt-get install -y git openjdk-8-jdk tomcat8

#Configuring tomcat
sed -i 's/port="8080"/port="80"/' /etc/tomcat8/server.xml
echo "AUTHBIND=yes" >> /etc/default/tomcat8 

#Copy application file
cd /tmp
git clone git@github.com:$GITPAGE 1>> /home/ubuntu/out.log 2>> /home/ubuntu/err.log

if [[ $? -eq 0 ]]; then
    temp=$(cp ./$CONTENT/${WARFILE} /var/lib/tomcat8/webapps/ 2>&1)
    if [[ $? -eq 0 ]]; then
        echo "The content was copied successfully" >> /home/ubuntu/out.log
    else
        echo "There was an error when copying content. The error was:" >> /home/ubuntu/err.log
        echo $temp >> /home/ubuntu/err.log
    fi
else
    echo "There was an error while cloning git page" 1>> /home/ubuntu/out.log 2>> /home/ubuntu/err.log
fi

service tomcat8 restart