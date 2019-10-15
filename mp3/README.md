## MiniProject 3

#### Usage instructions
`usage: create-env.sh --image-id <image-id> --key-name <key-name> --security-group <security-group> --count <count> elb-name <elb-name> --s3-bucket-name <s3-bucket-name>`

#### FrontEnd
The application has been implemented in Java EE 7.
The application run over Tomcat 8.5

The code was implemented using Eclipse JEE with AWS credentials configured.
To access to the webpage: http://{ip}/mp3


#### Backend
The application that process the images has been writing using Python

Application fails when try to upload the new image

The application is placed in /usr/share/improcessing
Logs from application goes to /var/log/improcessing

Clients are configured to work on region "us-east-2"
Notifications via SMS is not executed in the code


Update: 12/02/2018 2:55
1 Add RDS Read-Replica
    a. In the frontend src/aws/RDSConnectionManager
    b. Application allows session. However there is a redirection issue.
    c. There are two new pages
2 Gallery image display the raw and finished images. When the image is created the first time the user visit /gallery it only show the images related to the user
3 admin page
   a. There is a possibility to dump the database
   b. NOT IMPLEMENTED
4 Implement AutoScaling Group and AutoScaling Launch Configuration

There is just one user: admin/admin

