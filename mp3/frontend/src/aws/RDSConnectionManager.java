package aws;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.amazonaws.AmazonClientException;
import com.amazonaws.auth.InstanceProfileCredentialsProvider;
import com.amazonaws.auth.profile.ProfileCredentialsProvider;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.rds.AmazonRDS;
import com.amazonaws.services.rds.AmazonRDSClientBuilder;
import com.amazonaws.services.rds.model.CreateDBSnapshotRequest;
import com.amazonaws.services.rds.model.InvalidDBInstanceStateException;
import com.amazonaws.services.rds.model.SnapshotQuotaExceededException;

public class RDSConnectionManager {
	private static String RDS_DB_NAME;
	private static String RDS_USERNAME;
	private static String RDS_PASSWORD;
	private static String JDBC_URL;
	private static RDSConnectionManager rds = null;
	private static int contador = 1;
	private static AmazonRDS rdsClient;
	
	//READ DATABASE REPLICA 
	private static String JDBC_URL_READ;
	
	private RDSConnectionManager() throws SQLException  {
			Map<String,String> env = System.getenv();
			String RDS_HOSTNAME = env.get("RDS_HOSTNAME");
			String RDS_PORT = env.get("RDS_PORT");
			String RDS_HOSTNAME_READ = env.get("RDS_HOSTNAME_READ"); //HOSTNAME READ DATABASE REPLICA
			RDS_DB_NAME = env.get("RDS_DB_NAME");
			RDS_USERNAME = env.get("RDS_USERNAME");
			RDS_PASSWORD = env.get("RDS_PASSWORD");
			
			/*String RDS_HOSTNAME = "mp2-dgalan-db.cghfhejzffux.us-east-2.rds.amazonaws.com";
			String RDS_PORT = "3306";
			RDS_DB_NAME = "mp2";			
			RDS_USERNAME = "root";
			RDS_PASSWORD = "mypassword";
			*/
			JDBC_URL  = "jdbc:mysql://" + RDS_HOSTNAME + ":" + RDS_PORT + "/" + RDS_DB_NAME;
			JDBC_URL_READ = "jdbc:mysql://" + RDS_HOSTNAME_READ + ":" + RDS_PORT + "/" + RDS_DB_NAME;
			
			/*Connection con = RDSConnectionManager.getDBConnection();
			if (con != null) {
				con.close();
			}
			*/
			
			//ProfileCredentialsProvider credentialsProvider = new ProfileCredentialsProvider();
			InstanceProfileCredentialsProvider credentialsProvider = InstanceProfileCredentialsProvider.getInstance();
			
	        try {
	            credentialsProvider.getCredentials();
	            rdsClient = AmazonRDSClientBuilder.standard()
	            		.withCredentials(credentialsProvider)
	            		.withRegion(Regions.US_EAST_2)
	                    .build();
	        	//rdsClient = AmazonRDSClientBuilder.standard().build();
	            
	        } catch (Exception e) {
	            throw new AmazonClientException(
	                    "Cannot load the credentials from the credential profiles file. " +
	                    "Please make sure that your credentials file is at the correct " +
	                    "location (~\\.aws\\credentials), and is in valid format.",
	                    e);
	        }
	}
	
	private static Connection getDBConnection(String jdbc) throws SQLException { 
		return DriverManager.getConnection(jdbc, RDS_USERNAME, RDS_PASSWORD);	
	}
	
	public static RDSConnectionManager getInstance() throws ClassNotFoundException, SQLException  {
		if (rds == null) {
			rds = new RDSConnectionManager();
		} 
		return rds;
	}
	
	
	public long insertElement(String phoneNumber, String email, String raw_url) throws SQLException{
		Connection con = null;
		PreparedStatement preparedStmt = null;			
		long id=-1;
		
		String query = "INSERT INTO "+ RDS_DB_NAME +" (phone_number,email,s3_raw_url,s3_finished_url,job_status)"
				+ "VALUES (?,?,?,?,?)";
		
		try {
			con = getDBConnection(JDBC_URL);
			
			if (con != null) {
				preparedStmt = con.prepareStatement(query,Statement.RETURN_GENERATED_KEYS);

				preparedStmt.setString(1, phoneNumber);
				preparedStmt.setString(2, email);
				preparedStmt.setString(3, raw_url);
				preparedStmt.setNull(4, java.sql.Types.VARCHAR);
				preparedStmt.setInt(5, 1);
		
				preparedStmt.executeUpdate();
				
				ResultSet rs = preparedStmt.getGeneratedKeys();

				if (rs.next()) {
				    id = rs.getLong(1);
				    System.out.println("Inserted ID: " + id); // display inserted record
				} 
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage());
			throw new SQLException();
		} finally {
			if (preparedStmt != null) {
				preparedStmt.close();
			}
			if (con != null) {
				con.close();
			}		
		}
		return id;
	}
	
	public void dbBackup() throws InvalidDBInstanceStateException,SnapshotQuotaExceededException {
		CreateDBSnapshotRequest request = new CreateDBSnapshotRequest().withDBSnapshotIdentifier("database-snapshot"+contador++).withDBInstanceIdentifier("mp2-dgalan-db");
		
		if (request != null) {
			rdsClient.createDBSnapshot(request);
		}
		System.out.println("DBSnapshot created");
	}
	
	
	
	
	public List<Map<String,String>> getPhotos() throws SQLException{
		List<Map<String,String>> list = new ArrayList<Map<String,String>>();
		Connection con = null;
		Statement stmt = null;			
		
		String query = "SELECT s3_raw_url, s3_finished_url FROM "+ RDS_DB_NAME;
		
		try {
			con = getDBConnection(JDBC_URL_READ);
			
	
			if (con != null) {
				stmt = con.createStatement();
				ResultSet rs = stmt.executeQuery(query);
		        while (rs.next()) {
		        	Map<String,String> map = new HashMap<String,String>();
		            String s3_raw_url = rs.getString("s3_raw_url");
		            String s3_finished_url = rs.getString("s3_finished_url");
		            map.put("s3_raw_url", s3_raw_url);
		            map.put("s3_finished_url", s3_finished_url);
		            list.add(map);
			    }
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage());
			throw new SQLException();
		} finally {
			if (stmt != null) {
				stmt.close();
			}
			if (con != null) {
				con.close();
			}		
		}
		return list;
	}
	
	public List<Map<String,String>> getPhotosByEmail(String email) throws SQLException{
		List<Map<String,String>> list = new ArrayList<Map<String,String>>();
		Connection con = null;
		Statement stmt = null;			
		
		String query = "SELECT s3_raw_url, s3_finished_url FROM "+ RDS_DB_NAME + " WHERE email='"+email+"'";
		
		try {
			con = getDBConnection(JDBC_URL_READ);
			
	
			if (con != null) {
				stmt = con.createStatement();
				ResultSet rs = stmt.executeQuery(query);
		        while (rs.next()) {
		        	Map<String,String> map = new HashMap<String,String>();
		            String s3_raw_url = rs.getString("s3_raw_url");
		            String s3_finished_url = rs.getString("s3_finished_url");
		            map.put("s3_raw_url", s3_raw_url);
		            map.put("s3_finished_url", s3_finished_url);
		            list.add(map);
			    }
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage());
			throw new SQLException();
		} finally {
			if (stmt != null) {
				stmt.close();
			}
			if (con != null) {
				con.close();
			}		
		}
		return list;
	}
}
