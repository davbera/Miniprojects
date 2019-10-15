package aws;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;

import javax.servlet.http.Part;

import com.amazonaws.AmazonClientException;
import com.amazonaws.AmazonServiceException;
import com.amazonaws.SdkClientException;
import com.amazonaws.auth.InstanceProfileCredentialsProvider;
import com.amazonaws.auth.profile.ProfileCredentialsProvider;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.CannedAccessControlList;
import com.amazonaws.services.s3.model.ObjectMetadata;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.amazonaws.services.s3.model.PutObjectResult;
import com.amazonaws.services.s3.model.S3Object;

public class S3Manager {
	private static String BUCKET_NAME; 
	private static String BUCKET_ORIG_IMAGE_FOLDER;
	
	private static S3Manager s3bucket = null;
	private static AmazonS3 s3Client = null;

	
	private S3Manager() {
		Map<String,String> env = System.getenv();
		BUCKET_NAME = env.get("BUCKET_NAME");
		BUCKET_ORIG_IMAGE_FOLDER = env.get("BUCKET_ORIG_IMAGE_FOLDER");
		
		//BUCKET_NAME = "dgb-images"; 
		//BUCKET_ORIG_IMAGE_FOLDER = "upload-images";
		
		//ProfileCredentialsProvider credentialsProvider = new ProfileCredentialsProvider();
		InstanceProfileCredentialsProvider credentialsProvider = InstanceProfileCredentialsProvider.getInstance();

		try {
			/*s3Client = AmazonS3ClientBuilder.standard().
					withCredentials(new DefaultAWSCredentialsProviderChain()).
					build();*/
			s3Client = AmazonS3ClientBuilder.standard()
					.withRegion(Regions.US_EAST_2)
					.withCredentials(credentialsProvider)
					.build();
		} catch (Exception e) {
            throw new AmazonClientException(
                    "Cannot load the credentials from the credential profiles file. " +
                    "Please make sure that your credentials file is at the correct " +
                    "location (~\\.aws\\credentials), and is in valid format.",
                    e);
        }
	}
	
	public static S3Manager getInstance() {
		if (s3bucket == null) {
			s3bucket = new S3Manager();			
		}
		
		return s3bucket;	
	}
	
   private String sha256Hash(String input) throws  UnsupportedEncodingException {
            MessageDigest md;
			try {
				md = MessageDigest.getInstance("SHA-256");
				md.reset();
            
				byte[] buffer = input.getBytes(StandardCharsets.UTF_8);
				//md.update(buffer);
				byte[] hash = md.digest(buffer);
					
				String hexStr = "";
            	for (int i = 0; i < hash.length; i++) {
                	hexStr +=  Integer.toString( ( hash[i] & 0xff ) + 0x100, 16).substring( 1 );
            	}
            	return hexStr;
			} catch (NoSuchAlgorithmException e) {
				e.printStackTrace();
				return input;
			}
        }
	
	/*
	 * Upload a file that is in memory instead in a folder (also called part)
	 */
	public String uploadObject(Part part) throws AmazonServiceException, SdkClientException {
		String url = null;
		try {
			InputStream inputStream = part.getInputStream();
			String date_out = new SimpleDateFormat("yyyyMMddhhmmss").format(new Date());
			String src_filename = part.getSubmittedFileName();
			String dst_filename = date_out + "_" + sha256Hash(src_filename) + ".jpg";
			String dst = BUCKET_ORIG_IMAGE_FOLDER + "/" + dst_filename;
				
			ObjectMetadata metadata = new ObjectMetadata();
			metadata.setContentType(part.getContentType());
			metadata.setContentLength(part.getSize());
				
			PutObjectRequest request = new PutObjectRequest(BUCKET_NAME, dst, inputStream, metadata);
			s3Client.putObject(request);	
			url = s3Client.getUrl(BUCKET_NAME, dst).toString();
			s3Client.setObjectAcl(BUCKET_NAME, dst, CannedAccessControlList.PublicRead);
		
		} catch (IOException ex) {
			System.out.println(ex.getMessage());
		}
		return url;
	}
	
	
	public S3Object getObject() {
		S3Object o = null;
		try {
	//		S3Object o = s3.getObject(BUCKET_NAME, key_name);
			s3Client.getUrl(BUCKET_NAME, BUCKET_ORIG_IMAGE_FOLDER + "");
		} catch (AmazonServiceException ex) {
		    System.err.println(ex.getErrorMessage());
		    System.exit(1);
		}
		return o;
	}
	
}
