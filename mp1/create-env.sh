#!/bin/bash

USERDATAFILE=create-app.sh

#Checking parameters
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --image-id)
            IMAGEID="$2"
            ;;
        --key-name)
            KEYNAME="$2"
            ;;
        --security-group)
            SECURITYGROUP="$2"
            ;;
        --count)
            COUNT="$2"
            if [[ ! $COUNT =~ '^[1-9]$' ]]; then
                echo "Count should be a number between 1 and 9"
                exit 1
            fi
            ;;
        --elb-name)
            ELBNAME="$2"
            ;;
        --s3-bucket-name)
            S3BUCKETNAME="$2"
            ;;
        *)
            echo "Option $i is not known"
            exit 1
    esac
    shift
    shift
done

#Define default values if they were not defined
if [[ -z "${IMAGEID}" ]]; then
    IMAGEID="ami-042077aa44b230ef1"
    echo "image-id was not defined. Do you want to define it (Y/N)? [Default image-id is '${IMAGEID}']"
    read -n 1 OPTION
    echo
    if [ "$OPTION" == "Y" ] || [ "$OPTION" == 'y' ]; then
        echo "Insert the value of the image id"
        read IMAGEID
        echo
        while read IMAGEID && [[ ! "$IMAGEID" =~ ^ami-[a-z0-9]+$ ]]; do
            echo "Image identifier shall start as ami-* and contain numbers and lowercase letters"
        done
        echo
    fi
fi
if [[ -z "${KEYNAME}" ]]; then
	KEYNAME=dgb-544-2018
    echo "key-name was not defined. Do you want to define it (Y/N)? [Default key-name is '${KEYNAME}']"
    read -n 1 OPTION
    echo
    if [ "$OPTION" == "Y" ] || [ "$OPTION" == 'y' ]; then
        echo "Insert the value of the key-name"
       
        while read KEYNAME && [[ "$KEYNAME" =~ ( |\') ]]; do
            echo "Keyname shall not contain any space"
        done
        echo
    fi
fi
if [[ -z "${SECURITYGROUP}" ]]; then
	SECURITYGROUP=dgb-sg
    echo "security-group was not defined. Do you want to define it (Y/N)? [Default security-group is '${SECURITYGROUP}']"
    read -n 1 OPTION
    echo
    if [ "$OPTION" == "Y" ] || [ "$OPTION" == 'y' ]; then
        echo "Insert the value of the security-group"
        while read SECURITYGROUP && [[ "$SECURITYGROUP" =~ ( |\') ]]; do
            echo
            echo "Security group shall not contain any space"
        done
        echo
  
    fi
fi

#Check if security group exist
if [ -z `aws ec2 describe-security-groups --filters Name=group-name,Values=$SECURITYGROUP --query "SecurityGroups[*].{Name:GroupName}"` ]; then
    echo "The security-group $SECURITYGROUP does not exist"
    exit 1
fi

if [[ -z "${COUNT}" ]]; then
	COUNT=3
    echo "count was not defined. Do you want to define it (Y/N)? [Default number of instances to be created is '${COUNT}']"
    read -n 1 OPTION
    echo
    if [ "$OPTION" == "Y" ] || [ "$OPTION" == 'y' ]; then
        echo "Insert the value of the number of instances to be created"
        read -n 1 COUNT
        echo
        if [[ ! "$COUNT" =~ '^[1-9]$' ]]; then
            echo "The introduced caracter should be a number between 1 and 9"
            exit 1
        fi
    fi 
fi
if [[ -z "${ELBNAME}" ]]; then
	ELBNAME="my-load-balancer"
    echo "elb-name was not defined. Do you want to define it (Y/N)? [Default elb name is '${ELBNAME}']"
    read -n 1 OPTION
    echo
    if [ "$OPTION" == "Y" ] || [ "$OPTION" == 'y' ]; then
        echo "Insert the name of the load balancer"
        
        while read ELBNAME && [[ "$ELBNAME" =~ ( |\') ]]; do
            echo
            echo "Load balancer name shall not contain any space"
        done
        echo
    fi
fi
if [[ -z "${S3BUCKETNAME}" ]]; then
	S3BUCKETNAME=dgb-images
    echo "s3-bucket-name was not defined. Do you want to define it (Y/N)? [Default s3 bucket name is '${S3BUCKETNAME}']"
    read -n 1 OPTION
    echo
    if [ "$OPTION" == "Y" ] || [ "$OPTION" == 'y' ]; then
        echo "Insert the name of the bucket"
        
        while read S3BUCKETNAME && [[ "$S3BUCKETNAME" =~ ( |\') ]]; do
            echo
            echo "Bucket name shall not contain any space"
        done
        echo
    fi
fi

#Create instances
echo "Creating instances..."
if [ -a "$USERFILEDATA" ]; then
    temp=$(aws ec2 run-instances --image-id $IMAGEID --count $COUNT --instance-type t2.micro --key-name $KEYNAME --security-groups $SECURITYGROUP --user-data file://$USERFILEDATA 2>&1)
else 
    echo "No additional file parameter has been specified"
    temp=$(aws ec2 run-instances --image-id $IMAGEID --count $COUNT --instance-type t2.micro --key-name $KEYNAME --security-groups $SECURITYGROUP 2>&1)    
fi

if [ $? -eq 0 ]; then
    echo "Instances successfully created"
else
    echo "There was a problem creating the instances. The error is:"
    echo $temp
    exit 1
fi