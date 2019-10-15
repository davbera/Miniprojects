#!/bin/bash

# David Galan Berasaluce
# Illinois Institute of Technology
# ITMO 544 : Cloud Computing Technologies
# Miniproject 2

#usage: create-env.sh --image-id <image-id> --key-name <key-name> --security-group <security-group> 
#       --count <count> elb-name <elb-name> --s3-bucket-name <s3-bucket-name>


BACKENDDATAFILE="create-app-b.sh"
FRONTENDDATAFILE="create-app-f.sh"
AVA_ZONES=$(aws ec2 describe-availability-zones --query "AvailabilityZones[*].ZoneName")

#Database variables
RDS_USERNAME="root"
RDS_PASSWORD="mypassword"
RDS_DB_NAME="mp3" #dataserver
RDS_DB_ID="mp3-dgalan-db"

#S3 Variables
#BUCKET_NAME="dgb-images"
BUCKET_ORIG_IMAGE_FOLDER="upload-images"
BUCKET_DEST_IMAGE_FOLDER="transformed-images"

#SQS Variables
QUEUE_NAME="MyQueue1"

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
            BUCKET_NAME="$2"
            ;;
        --default)
            IMAGEID="ami-042077aa44b230ef1"
            KEYNAME="dgb-544-2018"
            SECURITYGROUP="dgb-sg"
            COUNT=3
            ELBNAME="my-load-balancer"
            BUCKET_NAME="dgb-images"
            ;;
        *)
            echo "usage: create-env.sh --image-id <image-id> --key-name <key-name> --security-group <security-group> --count <count> elb-name <elb-name> --s3-bucket-name <s3-bucket-name>"
            exit 1
    esac
    shift
    shift
done

#Checking whether every parameter was defined
if [[ -z "${IMAGEID}" ]] || [[ -z "${KEYNAME}" ]] || [[ -z "${SECURITYGROUP}" ]] || [[ -z "${COUNT}" ]] || [[ -z "${ELBNAME}" ]] || [[ -z "${BUCKET_NAME}" ]]; then
    echo "usage: create-env.sh --image-id <image-id> --key-name <key-name> --security-group <security-group> --count <count> elb-name <elb-name> --s3-bucket-name <s3-bucket-name>"
    exit 1
fi

#Checking whether security group exists
if [ -z `aws ec2 describe-security-groups --filters Name=group-name,Values=$SECURITYGROUP --query "SecurityGroups[*].{Name:GroupName}"` ]; then
    echo "The security-group $SECURITYGROUP does not exist"
    exit 1
fi

#Create database
echo "Creating database..."
temp=$(aws rds create-db-instance --db-name $RDS_DB_NAME --db-instance-identifier $RDS_DB_ID --master-username $RDS_USERNAME --master-user-password $RDS_PASSWORD --engine mysql --db-instance-class db.t2.micro --allocated-storage 5 2>&1)
if [ $? -eq 0 ]
    echo "Database successfully created"
else 
    echo "There was a problem while creating the Database. The error was"
    echo $temp
    exit 1
fi

RDS_HOSTNAME=$(aws rds describe-db-instances --db-instance-identifier $RDS_DB_ID --query 'DBInstances[*].Endpoint.Address')
RDS_PORT=$(aws rds describe-db-instances --db-instance-identifier $RDS_DB_ID --query 'DBInstances[*].Endpoint.Port')


#Create database replica
echo "Creating database replica...."
temp=$(aws rds create-db-instance-read-replica --db-instance-identifier "${RDS_DB_ID}-read" --source-db-instance-identifier "${RDS_DB_ID}" 2>&1)

if [ $? -eq 0 ]
    echo "Database successfully created"
else 
    echo "There was a problem while creating the Database. The error was"
    echo $temp
    exit 1
fi

RDS_HOSTNAME_READ=$(aws rds describe-db-instances --db-instance-identifier "${RDS_DB_ID}-read" --query 'DBInstances[*].Endpoint.Address')
RDS_PORT_READ=$(aws rds describe-db-instances --db-instance-identifier "${RDS_DB_ID}-read" --query 'DBInstances[*].Endpoint.Port')

#Change variable values
if [ -a "$BACKENDDATAFILE" ]; then
    sed -i "s/^\(RDS_USERNAME=\).*/RDS_USERNAME=$RDS_USERNAME/" ./$BACKENDDATAFILE
    sed -i "s/^\(RDS_PASSWORD=\).*/RDS_PASSWORD=$RDS_PASSWORD/" ./$BACKENDDATAFILE
    sed -i "s/^\(RDS_DB_NAME=\).*/RDS_DB_NAME=$RDS_DB_NAME/" ./$BACKENDDATAFILE
    sed -i "s/^\(RDS_PORT=\).*/RDS_PORT=$RDS_PORT/" ./$BACKENDDATAFILE
    sed -i "s/^\(RDS_HOSTNAME=\).*/RDS_HOSTNAME=$RDS_HOSTNAME/" ./$BACKENDDATAFILE
    sed -i "s/^\(RDS_PORT_READ=\).*/RDS_PORT_READ=$RDS_PORT_READ/" ./$BACKENDDATAFILE
    sed -i "s/^\(RDS_HOSTNAME_READ=\).*/RDS_HOSTNAME_READ=$RDS_HOSTNAME_READ/" ./$BACKENDDATAFILE
    sed -i "s/^\(BUCKET_NAME=\).*/BUCKET_NAME=$BUCKET_NAME/" ./$BACKENDDATAFILE
    sed -i "s/^\(BUCKET_ORIG_IMAGE_FOLDER=\).*/BUCKET_ORIG_IMAGE_FOLDER=$BUCKET_ORIG_IMAGE_FOLDER/" ./$BACKENDDATAFILE
    sed -i "s/^\(BUCKET_DEST_IMAGE_FOLDER=\).*/BUCKET_DEST_IMAGE_FOLDER=$BUCKET_DEST_IMAGE_FOLDER/" ./$BACKENDDATAFILE
    sed -i "s/^\(QUEUE_NAME=\).*/QUEUE_NAME=$QUEUE_NAME/" ./$BACKENDDATAFILE
fi
if [ -a "$FRONTENDDATAFILE" ]; then
    sed -i "s/^\(RDS_USERNAME=\).*/RDS_USERNAME=$RDS_USERNAME/" ./$FRONTENDDATAFILE
    sed -i "s/^\(RDS_PASSWORD=\).*/RDS_PASSWORD=$RDS_PASSWORD/" ./$FRONTENDDATAFILE
    sed -i "s/^\(RDS_DB_NAME=\).*/RDS_DB_NAME=$RDS_DB_NAME/" ./$FRONTENDDATAFILE
    sed -i "s/^\(RDS_PORT=\).*/RDS_PORT=$RDS_PORT/" ./$FRONTENDDATAFILE
    sed -i "s/^\(RDS_HOSTNAME=\).*/RDS_HOSTNAME=$RDS_HOSTNAME/" ./$FRONTENDDATAFILE
    sed -i "s/^\(RDS_PORT_READ=\).*/RDS_PORT_READ=$RDS_PORT_READ/" ./$FRONTENDDATAFILE
    sed -i "s/^\(RDS_HOSTNAME_READ=\).*/RDS_HOSTNAME_READ=$RDS_HOSTNAME_READ/" ./$FRONTENDDATAFILE
    sed -i "s/^\(BUCKET_NAME=\).*/BUCKET_NAME=$BUCKET_NAME/" ./$FRONTENDDATAFILE
    sed -i "s/^\(BUCKET_ORIG_IMAGE_FOLDER=\).*/BUCKET_ORIG_IMAGE_FOLDER=$BUCKET_ORIG_IMAGE_FOLDER/" ./$FRONTENDDATAFILE
    sed -i "s/^\(BUCKET_DEST_IMAGE_FOLDER=\).*/BUCKET_DEST_IMAGE_FOLDER=$BUCKET_DEST_IMAGE_FOLDER/" ./$FRONTENDDATAFILE
    sed -i "s/^\(QUEUE_NAME=\).*/QUEUE_NAME=$QUEUE_NAME/" ./$FRONTENDDATAFILE
fi

#Defining policy
aws iam create-role --role-name mp3-role --assume-role-policy-document file://role-policy.json
aws iam attach-role-policy --role-name mp3-role --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
aws iam create-instance-profile --instance-profile-name mp3-profile
aws iam add-role-to-instance-profile --instance-profile-name mp3-profile --role-name mp3-role

#Create frontend instances
echo "Creating frontend instances..."
if [ ! -z "$FRONTENDDATAFILE" ]; then
    if [ -f "$FRONTENDDATAFILE" ]; then
        temp=$(aws autoscaling create-launch-configuration --launch-configuration-name dgb-asg-lc --image-id $IMAGEID --iam-instance-profile Name=mp3-profile --instance-type t2.micro --key-name $KEYNAME --security-groups $SECURITYGROUP --user-data file://$FRONTENDDATAFILE 2>&1)
    else
        echo "The file data $FRONTENDDATAFILE does not exist"
        exit 1
    fi
else 
    echo "No additional file parameter has been specified"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "Frontend instances successfully created"
else
    echo "There was a problem creating the frontend instances. The error is:"
    echo $temp
    exit 1
fi


#Create backend instances
echo "Creating backend instances..."
if [ ! -z "$BACKENDDATAFILE" ]; then
    if [ -f "$BACKENDDATAFILE" ]; then
        temp=$(aws ec2 run-instances --image-id $IMAGEID --instance-type t2.micro --key-name $KEYNAME --security-groups $SECURITYGROUP --iam-instance-profile Name=mp3-profile --user-data file://$BACKENDDATAFILE --query 'Instances[*].InstanceId'  2>&1)
    else
        echo "The file data $BACKENDDATAFILE does not exist"
        exit 1   
    fi
else 
    echo "No additional file parameter has been specified"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "Backend instance successfully created"
    BACKEND_INSTANCES=$temp
else
    echo "There was a problem creating the backend instance. The error is:"
    echo $temp
    exit 1
fi

echo "Load balancer with name '$ELBNAME' is going to be created..."
temp=$(aws elb create-load-balancer --load-balancer-name $ELBNAME --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" --availability-zones $AVA_ZONES 2>&1)
if [ $? -eq 0 ]; then
    echo "Load balancer $ELBNAME successfully created"
else
    echo "There was an error when creating the load-balancer. The error was:"
    echo $temp
    exit 1
fi


echo "Creating load-balancer sticky policy to loadbalancer '$ELBNAME'..."
temp=$(aws elb create-lb-cookie-stickiness-policy --load-balancer-name $ELBNAME --policy-name my-cookie-policy 2>&1)
if [ $? -eq 0 ]; then
    echo "Sticky policy successfull created. Applying policy to the load-balancer '$ELBNAME'"
    temp=$(aws elb set-load-balancer-policies-of-listener --load-balancer-name $ELBNAME --load-balancer-port 80 --policy-names my-cookie-policy 2>&1)
    if [ $? -eq 0 ]; then
        echo "Sticky policy applied successfully"
    else
        echo "There was an error while applying policy to load-balancer $ELBNAME. The error was"
        echo $temp
    fi
else 
    echo "There was an error while creating sticky policy. The error was:"
    echo $temp
fi

sleep 25

temp=$(aws autoscaling create-auto-scaling-group --auto-scaling-group-name dgb-asg --launch-configuration-name dgb-asg-lc --load-balancer-names $ELBNAME --health-check-type ELB --health-check-grace-period 120 --min 2 --max 6 --desired-capacity 3 --availability-zones $AVA_ZONES 2>&1)


#S3 Object based storage
echo "Creating bucket with name $BUCKET_NAME..."
temp=$(aws s3api create-bucket --bucket $BUCKET_NAME --region us-east-1 2>&1)


#SQS QUEUE
echo "Creating SQS queue with name $QUEUE_NAME..."
temp=$(aws sqs create-queue --queue-name $QUEUE_NAME 2>&1)

if [ $? -eq 0 ]
    echo "SQS Queue successfully created"
else 
    echo "There was a problem while creating the SQS Queue. The error was"
    echo $temp
fi
