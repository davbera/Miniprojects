package com.mp3.dgalan;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import aws.RDSConnectionManager;

@WebServlet(
		description = "Gallery Servlet", 
		urlPatterns = ("/gallery"))
public class GalleryServlet extends HttpServlet  {
	private static final long serialVersionUID = 1L;

	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {	
		List<Map<String,String>> images = null;

		RDSConnectionManager rds;
		try {
			rds = RDSConnectionManager.getInstance();
			HttpSession session = request.getSession(false);
			
			if (session != null) {
				String email = (String) session.getAttribute("email");
				if (email != null) {
					images = rds.getPhotosByEmail(email);
					session.removeAttribute("email");
				} else {
					images = rds.getPhotos();
				}
			} else {
				images = rds.getPhotos();
			}
		} catch (ClassNotFoundException | SQLException e) {
			e.printStackTrace();
		}

		request.setAttribute("images",images);
		
		RequestDispatcher rd=request.getRequestDispatcher("gallery.jsp");
		rd.forward(request, response);
	}
}
