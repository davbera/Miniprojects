package aws;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Map;

public class RDSConnectionManager {
	private static String RDS_DB_NAME;
	private static String RDS_USERNAME;
	private static String RDS_PASSWORD;
	private static String JDBC_URL;
	private static RDSConnectionManager rds = null;
	
	private RDSConnectionManager() throws SQLException  {
			Map<String,String> env = System.getenv();
			String RDS_HOSTNAME = env.get("RDS_HOSTNAME");
			String RDS_PORT = env.get("RDS_PORT");
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
				
			Connection con = RDSConnectionManager.getDBConnection();
			if (con != null) {
				con.close();
			}
	}
	
	private static Connection getDBConnection() throws SQLException { 
		return DriverManager.getConnection(JDBC_URL, RDS_USERNAME, RDS_PASSWORD);	
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
			con = getDBConnection();
			
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
}
