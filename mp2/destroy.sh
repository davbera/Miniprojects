#!/bin/bash

BUCKET=dgb-images

echo "Checking for pending or running instances..."
INSTANCES=`aws ec2 describe-instances --filters "Name=instance-state-name,Values=pending,running" --query 'Reservations[*].Instances[*].InstanceId'`

if [ ! -z "$INSTANCES" ]; then
    echo "The following Instances have been found: $INSTANCES"
    INSTANCES=(${INSTANCES// / })

    #if [ ${#INSTANCES[@]} -gt 0]
    echo "Attached volumes are going to be checked for each instance..."
    for i in `seq 0 $((${#INSTANCES[@]}-1))`
    do
        INSTANCE=${INSTANCES[$i]}
        VOLUMES=`aws ec2 describe-volumes --query 'Volumes[*].{ID:VolumeId}' --filters Name=attachment.instance-id,Values="$INSTANCE" Name=attachment.delete-on-termination,Values="false"`
        
        
        if [ ! -z "$VOLUMES" ];  then
            VOLUMES=(${VOLUMES// / })

            for j in `seq 0 $((${#VOLUMES[@]}-1))`
            do
                VOLUME=${VOLUMES[j]}
                echo "Volume $VOLUME is going to be detached from ${INSTANCE}..."
                temp=$(aws ec2 detach-volume --volume-id $VOLUME 2>&1)
                if [ $? -eq 0 ]; then
                    echo "Volume $VOLUME was sucessfully detached"
                else
                    echo "There was an error while detaching $VOLUME from ${INSTANCES[$i]}. The error was"
                    echo $temp
                fi
            done
        else 
            echo "Instance ${INSTANCE} has not attached any volume"
        fi
    done

    INSTANCES=$(IFS=, ; echo "${INSTANCES[*]}")
    VOLUMES=`aws ec2 describe-volumes --query 'Volumes[*].{ID:VolumeId}' --filters Name=attachment.instance-id,Values="${INSTANCES}" Name=attachment.delete-on-termination,Values="false"`

    INSTANCES=(${INSTANCES//,/ })
    temp=$(aws ec2 terminate-instances --instance-ids ${INSTANCES[@]}  2>&1)
    if [ $? -eq 0 ]; then
         echo "The instances were successfully removed"
         if [ ! -z "$VOLUMES" ]; then
            echo "Waiting for volumes to be in available status..."
            aws ec2 wait volume-available --volume-ids ${VOLUMES}
            echo "All the volumes were successfully detached and are in available status"
        fi
    else
         echo "There was a problem while removing instances. The error was:"
         echo $temp
    fi
else 
    echo "There are not pending or running instances to terminate"    
fi



echo "Checking for load-balancers..."
LOADBALANCER=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].LoadBalancerName'`
if [ ! -z "$LOADBALANCER" ]; then
    echo "Loadbalancer $LOADBALANCER is going to be deleted..."
    temp=$(aws elb delete-load-balancer --load-balancer-name $LOADBALANCER 2>&1)
    if [ $? -eq 0 ]; then
        echo "The load-balancer was successfully removed"
    else 
        echo "There was a problem while removing load-balancer. The error was:"
	echo $temp
    fi 
else
    echo "There is not any load balancer to delete"
fi


BUCKETS=`aws s3api list-buckets --query "Buckets[*].Name"`
echo "Checking for buckets to be removed..."

if [ ! -z "$BUCKETS" ]; then
    BUCKETS=(${BUCKETS// / })
    for i in `seq 0 $((${#BUCKETS[@]}-1))` 
    do
        OBJECTS=$(aws s3api list-objects --bucket ${BUCKETS[$i]} --query 'Contents[*].{Key: Key}')
        if [ "$OBJECTS" != 'None' ]; then
	    echo "The following objects are going to be removed:"
            echo $OBJECTS

            OBJECTS=(${OBJECTS// / })

            OBJECTSTODELETE='Objects=['

            for j in `seq 0 $((${#OBJECTS[@]}-1))` 
            do
                OBJECTSTODELETE="${OBJECTSTODELETE}{Key=${OBJECTS[$j]}}"

                if [ $j -ne $((${#OBJECTS[@]}-1)) ]; then
                    OBJECTSTODELETE="${OBJECTSTODELETE},"
                fi
            done
            OBJECTSTODELETE="${OBJECTSTODELETE}],Quiet=True"

            temp=$(aws s3api delete-objects --bucket ${BUCKETS[$i]} --delete "$OBJECTSTODELETE" 2>&1)
            if [ $? -eq 0 ]; then
               echo "The objects were successfully removed"
            else
		echo "There was a problem while removing objects. The error was:"
	  	echo $temp
            fi
        fi
        echo "The bucket ${BUCKETS[$i]} is going to be deleted..."
        temp=$(aws s3api delete-bucket --bucket ${BUCKETS[$i]} 2>&1)
	if [ $? -eq 0 ]; then
             echo "The bucket was successfully removed"
        else
             echo "There was a problem while removing bucket. The error was:"
	     echo $temp
	fi
    done 
else
    echo "There is not any bucket to remove" 
 fi


QUEUES=`aws sqs list-queues --query QueueUrls[*]`
if [ ! -z "$QUEUES" ]; then
    QUEUES=(${QUEUES// / })
    for i in `seq 0 $((${#QUEUES[@]}-1))` 
    do
        echo "Queue with url ${QUEUES[$i]} is going to be deleted...."
        temp=$(aws sqs delete-queue --queue-url ${QUEUES[$i]})
        if [ $? -eq 0 ]; then
             echo "The queue was successfully removed"
        else
            echo "There was a problem while removing the queue. The error was:"
	        echo $temp
	    fi
    done
else
    echo "There is not any queue to remove"
fi

echo "Destroying DB Instances..."
DBINSTANCES=`aws rds describe-db-instances --query 'DBInstances[*].DBInstanceIdentifier'`
DBINSTANCES=(${DBINSTANCES// / })
for i in `seq 0 $((${#QUEUES[@]}-1))`
do
    echo "Database with id ${DBINSTANCES[$i]} is going to be deleted...."
    temp=$(aws rds delete-db-instance --db-instance-identifier ${DBINSTANCES[$i]})
    if [ $? -eq 0 ]; then
            echo "The database was successfully removed"
    else
        echo "There was a problem while removing the queue. The error was:"
        echo $temp
    fi
done
