import boto3
import botocore
import os
import time
import mysql.connector
import urlparse
from PIL import Image, ImageFilter
from mysql.connector import errorcode
from contextlib import closing


rdsc = boto3.client('rds',region_name="us-east-2")
s3c = boto3.client('s3')
s3r = boto3.resource('s3')
sqs_c = boto3.client('sqs',region_name="us-east-2")
sqs_r = boto3.resource('sqs',region_name="us-east-2")
sns_c = boto3.client('sns',region_name="us-west-2")


RDS_USERNAME=os.environ['RDS_USERNAME']
RDS_PASSWORD=os.environ['RDS_PASSWORD']
RDS_DB_NAME=os.environ['RDS_DB_NAME']
RDS_HOSTNAME=os.environ['RDS_HOSTNAME']
RDS_PORT=os.environ['RDS_PORT']
BUCKET_NAME=os.environ['BUCKET_NAME']
BUCKET_ORIG_IMAGE_FOLDER=os.environ['BUCKET_ORIG_IMAGE_FOLDER']
BUCKET_DEST_IMAGE_FOLDER=os.environ['BUCKET_DEST_IMAGE_FOLDER']
QUEUE_NAME=os.environ['QUEUE_NAME']

DEST_FOLDER_IMAGES='tmp/'

config = {
   'host':RDS_HOSTNAME,
   'user':RDS_USERNAME,
   'passwd':RDS_PASSWORD,
   'database':RDS_DB_NAME,
}

while True:
    try:
        mydb = mysql.connector.connect(**config)
        break
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
	        print("Access denied to database")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
	        print("Database does not exist")
        else:
	        print(err)
        time.sleep(60)

print("Connection to database created")
	
#Create datatable if not exist	
with closing(mydb.cursor()) as cursor:
	sql = "CREATE TABLE IF NOT EXISTS " + RDS_DB_NAME + " (id INT AUTO_INCREMENT PRIMARY KEY, phone_number VARCHAR(12), email VARCHAR(255), s3_raw_url VARCHAR(255), s3_finished_url VARCHAR(255), job_status INT)"
	try:
		cursor.execute(sql)
	except mysql.connector.Error as err:
		print("Failed creating database: {}".format(err))
		exit(1)
	else:
		print("Table successfully created")

#RDS Functions
def get_element_by_id(id):
    mycursor = mydb.cursor()
    sql = "SELECT * FROM " + RDS_DB_NAME + " WHERE id = " + str(id)
    mycursor.execute(sql)
    data = mycursor.fetchone()
    result = None
    if data is not None:
        result = {'id':data[0],
                'phone_number':str(data[1]), 
                'email':str(data[2]), 
                's3_raw_url':str(data[3]), 
                's3_finished_url':str(data[4]), 
                'job_status':data[5]
        }
    return result

def insert(phone_number, email, s3_raw_url):
    with closing(mydb.cursor()) as cursor:
      sql = "INSERT INTO mp2 (phone_number,email,s3_raw_url,s3_finished_url,job_status) VALUES (%s,%s,%s,%s,%s)"
      values = (phone_number,email,s3_raw_url,None,1)
      cursor.execute(sql,values)
      mydb.commit()
      print("Element successfully inserted inserted")

def update_status(id,status):
    mycursor = mydb.cursor()
    sql = "UPDATE " + RDS_DB_NAME + " SET job_status = %s WHERE id = %s"
    values = (status, id)
    mycursor.execute(sql,values)
    mydb.commit()

def update_s3_finished_url(id,s3_finished_url):
    mycursor = mydb.cursor()
    sql = "UPDATE " + RDS_DB_NAME + " SET s3_finished_url = %s WHERE id = %s"
    values = (s3_finished_url, id)
    mycursor.execute(sql,values)
    mydb.commit()

	
#S3 Functions
queue = sqs_r.get_queue_by_name(QueueName=QUEUE_NAME)

def download_object(filename):
    KEY = BUCKET_ORIG_IMAGE_FOLDER + "/" + filename #image in s3
    dest_filename = DEST_FOLDER_IMAGES + filename
    try:
      s3r.Bucket(BUCKET_NAME).download_file(KEY, dest_filename)
    except botocore.exceptions.ClientError as e:
        print("The object does not exist.")
        return None
    return dest_filename


def upload_object(src_filename):
        src = src_filename
        dst = BUCKET_DEST_IMAGE_FOLDER + "/" + os.path.basename(src_filename)

        file_url=None
        try:
            
            s3c.upload_file(src,BUCKET_NAME,dst,ExtraArgs={'ACL':'public-read'})

            #data = open(DEST_FOLDER_IMAGES+file_s,'rb')
            #s3r.Bucket(BUCKET_NAME).put_object(Key=filename, Body=data)
            #TODO: Dar permisos de read
            #object_acl = s3r.ObjectAcl(BUCKET_NAME,filename)
            #object_acl.put(ACL='public-read')
            #s3r.ObjectAcl(BUCKET_NAME,filename).put(ACL='public-read')
            #s3c.upload_file(file_s,BUCKET_NAME,filename,ExtraArgs={'ACL': 'public-read'})
            file_url = '%s/%s/%s' % (s3c.meta.endpoint_url, BUCKET_NAME, dst)
            #data.close()
        except Exception as ex:
            print("Error uploading object")

        return file_url

	

#SNS Functions
def publish_message(phone_number,message):
    return sns_c.publish(PhoneNumber=phone_number,Message=message)

#ImageProcessing
def process_image(filename):
    try:
        img = Image.open(filename)
        new_img = Image.new("RGB",(2000,2000))
        img_r,img_g,img_b = img.split()
        new_img.paste(img,(0,0))
        new_img.paste(img_r,(1000,0))
        new_img.paste(img_g,(0,1000))
        new_img.paste(img_b,(1000,1000))

        new_img.save(filename)
        return new_img
    except Exception as ex:
        print("Error image processing")

while True:
  #SQS Check for sqs image
  message = queue.receive_messages(MaxNumberOfMessages=1)

  if not message:
    print("There is not message. Sleeping 10 seconds")
    time.sleep(10)
  else:
    id_photo = message[0].body
    print("Message received: " + id_photo)

    #Get param from database
    response = get_element_by_id(id_photo)
    print("Response received: ")
    print(response)

    s3_raw_url = response['s3_raw_url']

    filename = os.path.basename(s3_raw_url)
    phoneNumber = response['phone_number']
    email = response['email']

    #Download image
    photo = download_object(filename)
    print("Image downloaded")

    new_photo = process_image(photo)

    if new_photo is not None:
        #S3: Upload image
        print("Uploading object to:")
        print(photo)
        
        url_new_photo = upload_object(photo)

        if url_new_photo is not None:
            update_s3_finished_url(id_photo,url_new_photo)
            update_status(id_photo,0)
            queue.delete_messages(
                    Entries=[
                    {
                      'Id': message[0].message_id,
                      'ReceiptHandle': message[0].receipt_handle
                    },
                ]
            )
            message = "You can check the image in the following link:" + str(url_new_photo)
            print(message)
            #SNS: Send notification
            #publish_message(phone_number,message) 
      

mydb.close()