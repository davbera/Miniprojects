package com.mp3.dgalan;

import java.io.IOException;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.amazonaws.services.rds.model.InvalidDBInstanceStateException;
import com.amazonaws.services.rds.model.SnapshotQuotaExceededException;

import aws.RDSConnectionManager;

/**
 * Servlet implementation class DBbackupServlet
 */
@WebServlet("/dbbackup")
public class DBbackupServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       

/*	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		response.getWriter().append("Served at: ").append(request.getContextPath());
	}
*/

	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		RDSConnectionManager rds;
		try {
			rds = RDSConnectionManager.getInstance();
			rds.dbBackup();
			request.setAttribute("message", "Database snapshot successfully created");
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (SQLException e) {
			e.printStackTrace();
		} catch (InvalidDBInstanceStateException ex) {
			request.setAttribute("message", "Database is not in the available state");
			ex.printStackTrace();
		} catch (SnapshotQuotaExceededException ex) {
			request.setAttribute("message", "Number of snapshot exceeded");
			ex.printStackTrace();
		}

		request.getRequestDispatcher("admin.jsp").forward(request, response);
	}

}
