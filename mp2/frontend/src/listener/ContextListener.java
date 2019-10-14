package listener;

import java.sql.SQLException;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

import aws.RDSConnectionManager;

@WebListener
public class ContextListener implements ServletContextListener {

	public void contextDestroyed(ServletContextEvent arg0) {

		System.out.println("Database connection closed for Application.");
	}

	
	public void contextInitialized(ServletContextEvent arg0) {
		//Test DB Connection
		try {
			Class.forName("com.mysql.cj.jdbc.Driver");
			RDSConnectionManager.getInstance();
			System.out.println("Database connection initialized for Application.");
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		
	}

	
	
	
}
