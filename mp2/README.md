## MiniProject 2

#### Introduction
Miniproject 2 is one of the miniprojects from ITMO x44 Cloud Computing Technologies. 


#### Usage instructions
`usage: create-env.sh --image-id <image-id> --key-name <key-name> --security-group <security-group> --count <count> elb-name <elb-name> --s3-bucket-name <s3-bucket-name>`

#### FrontEnd
The application has been implemented in Java EE 7.
The application run over Tomcat 8.5

The code was implemented using Eclipse JEE with AWS credentials configured.
To access to the webpage: http://{ip}/mp2

It fail when uploading the image, it could be a credential issues or database information misconfiguration
In the local machine works:
![Frontend running](https://github.com/illinoistech-itm/dgalanberasaluce/blob/master/itmo-544/images/mp2/upload-image.jpg)

#### Backend
The application that process the images has been writing using Python

Application fails when try to upload the new image

The application is placed in /usr/share/improcessing
Logs from application goes to /var/log/improcessing

Clients are configured to work on region "us-east-2"

The processing of the image should do something as:
Given the following image
![Initial Image](https://github.com/illinoistech-itm/dgalanberasaluce/blob/master/itmo-544/images/new_image.jpg)

Transform to
![Processed Image](https://github.com/illinoistech-itm/dgalanberasaluce/blob/master/itmo-544/images/image_process.jpg)