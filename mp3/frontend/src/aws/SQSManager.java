package aws;
import java.util.Map;

import com.amazonaws.AmazonClientException;
import com.amazonaws.auth.InstanceProfileCredentialsProvider;
import com.amazonaws.auth.profile.ProfileCredentialsProvider;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.sqs.AmazonSQS;
import com.amazonaws.services.sqs.AmazonSQSClientBuilder;
import com.amazonaws.services.sqs.model.InvalidMessageContentsException;
import com.amazonaws.services.sqs.model.SendMessageRequest;


public class SQSManager {
	private static String QUEUE_NAME;
	
	private static SQSManager sqsManager = null;
	private static AmazonSQS sqs = null;
	
	private SQSManager() {
		Map<String,String> env = System.getenv();
		QUEUE_NAME = env.get("QUEUE_NAME");
		//QUEUE_NAME = "MyQueue1";
		//ProfileCredentialsProvider credentialsProvider = new ProfileCredentialsProvider();
		InstanceProfileCredentialsProvider credentialsProvider = InstanceProfileCredentialsProvider.getInstance();
		
        try {
          
            sqs = AmazonSQSClientBuilder.standard()
            		.withCredentials(credentialsProvider)
            		.withRegion(Regions.US_EAST_2)
                    .build();
            
            /*sqs = AmazonSQSClientBuilder.standard().
			withCredentials(new DefaultAWSCredentialsProviderChain()).
			build();*/
        } catch (Exception e) {
            throw new AmazonClientException(
                    "Cannot load the credentials from the credential profiles file. " +
                    "Please make sure that your credentials file is at the correct " +
                    "location (~\\.aws\\credentials), and is in valid format.",
                    e);
        }
	}
	
	public static SQSManager getInstance() {
		if (sqsManager == null) {
			sqsManager = new SQSManager();			
		}
		
		return sqsManager;	
	}
	
	public void sendMessage(String message) throws Exception {
		//A message can include only XML, JSON, and unformatted text
		String queueUrl = sqs.getQueueUrl(QUEUE_NAME).getQueueUrl();
		SendMessageRequest send_msg_request = new SendMessageRequest(queueUrl,message);
		try {
			sqs.sendMessage(send_msg_request);
		} catch (InvalidMessageContentsException ex) {
			System.out.println(ex.getMessage());
			throw new Exception();
		} catch (UnsupportedOperationException ex) {
			System.out.println(ex.getMessage());
			throw new Exception();
		}
	}
}
