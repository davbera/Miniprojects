#!/bin/bash

GITPAGE='illinoistech-itm/dgalanberasaluce.git'
CONTENT='dgalanberasaluce/itmo-544/mp2/backend'
APPNAME='improcessing'
APPDIR="/usr/share/$APPNAME" #Folder to save executable content
LOGFOLDER="/var/log/$APPNAME"

RDS_USERNAME=
RDS_PASSWORD=
RDS_DB_NAME=
RDS_PORT=
RDS_HOSTNAME=
BUCKET_NAME=
BUCKET_ORIG_IMAGE_FOLDER=
BUCKET_DEST_IMAGE_FOLDER=
QUEUE_NAME=

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

export RDS_USERNAME=$RDS_USERNAME
export RDS_PASSWORD=$RDS_PASSWORD
export RDS_DB_NAME=$RDS_DB_NAME
export RDS_PORT=$RDS_PORT
export RDS_HOSTNAME=$RDS_HOSTNAME
export BUCKET_NAME=$BUCKET_NAME
export BUCKET_ORIG_IMAGE_FOLDER=$BUCKET_ORIG_IMAGE_FOLDER
export BUCKET_DEST_IMAGE_FOLDER=$BUCKET_DEST_IMAGE_FOLDER
export QUEUE_NAME=$QUEUE_NAME

apt-get update
apt-get install -y git python-pip python2.7

pip install boto3 2>> /home/ubuntu/err.log
pip install --user Pillow 2>> /home/ubuntu/err.log
pip install --user numpy 2>> /home/ubuntu/err.log
pip install --user mysql-connector 2>> /home/ubuntu/err.log

mkdir "$APPDIR" 2>> /home/ubuntu/err.log
mkdir "$APPDIR/tmp" 2>> /home/ubuntu/err.log
mkdir "${LOGFOLDER}" 2>> /home/ubuntu/err.log

cd /tmp
git clone git@github.com:$GITPAGE 1>> /home/ubuntu/out.log 2>> /home/ubuntu/err.log

if [[ $? -eq 0 ]]; then
    temp=$(cp ./$CONTENT/*.py "${APPDIR}" 2>&1)
    if [[ $? -eq 0 ]]; then
        echo "The content was copied successfully" >> /home/ubuntu/out.log
        cd ${APPDIR}
        chmod +x main.py
        python main.py 1>> "${LOGFOLDER}/out.log" 2>> "${LOGFOLDER}/err.log" & 
    else
        echo "There was an error when copying content. The error was:" >> /home/ubuntu/err.log
        echo $temp >> /home/ubuntu/err.log
    fi
else
    echo "There was an error while cloning git page" 1>> /home/ubuntu/out.log 2>> /home/ubuntu/err.log
fi