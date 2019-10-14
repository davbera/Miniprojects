## MiniProject 1

#### Introduction
Miniproject 1 is one of the miniprojects from ITMO x44 Cloud Computing Technologies. This first project tries to apply the adquired basical knowledge about providing a web service applicacion. AWS is used.

The architecture consist of (default: 3) instances that works as webservers, a load balancer, an additional volume per instance and a S3 Object based storage.


#### Usage instructions
There are two scripts: create-env.sh, create-app.sh and destroy.sh

##### create-env.sh
create-env.sh is the main script. It receives the following parameters: Image-id, Key-name, Security-Group, Count, ELB-name, S3-bucket-name
Count is the number of instances to be created.

There are two ways to specify these parameters:
1. Passing them as positional parameters preceeded by the following options: --image-id,--key-name,--security-group,--count,--elb-name,--s3-bucket-name
For example: 

```
./create-env.sh --image-id ami-042077aa44b230ef1 --key-name dgb-544-2018 --security-group dgb-sg --count 3 --elb-name my-load-balancer --s3-bucket-name dgb-images
```

2. If any of the options was not specified, it is interactivaly asked for in the console.

If no parameters are specified then default defined parameters are used.

Some comments about the implementation:
- The load-balancer is created in the availability zones of the user who executes the script. An option to introduce that ask to the user for this parameter is commented in the script to make it more lightweight for testing purposes.
- Two types of sticky policies can be defined in an aws load balancer: app cookie and session lifetime cookie. In this project I decided to use session lifetime cookie without specifiying a value, so then the sticky session should last for the duration of the browser session.
- To not make more complex the because it is considered it goes futher from the purpose of the project, the location where the volumes are mounted are statically defined in /dev/xvdf
- If there is an error when creating the instances or load-balancer the script stops.
- The maximum value count accept is 9


##### create-app.sh
This script is used by the instances when are being initating. It installs an apache webserver and clones code from this repository (www folder).
It also mount a volume to /dev/xvdf.
It can take time to mount the volume because it has to wait until the volume is available. A countdown with a value of 10 is specified, therefore it takes as much as 10 times * 5 second of sleep = 50s


##### destroy-env.sh
This script remove all the instances, load-balancer, volumes and s3 storage

Volumes are checked two times, first for those that are attached to an instance (and they are not root volumes) and second for those that are not attached to any instance. Root volumes are removed when instances are removed.

This script can take time because it waits until the volumes are detached to delete them. As the volumes are mounted in the instance, the instance must be removed before the volumes are in available status.

Anyway, if the script freezes when waiting to the volumes to be in available status to be destroyed, you can stop the script and run it again. Also take into account that maybe it is needed to run it again because maybe the additional volumes are not yet removed.

```
./destroy.sh
```