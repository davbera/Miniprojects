package com.mp3.dgalan;

import java.io.IOException;
import java.sql.SQLException;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import aws.RDSConnectionManager;
import aws.S3Manager;
import aws.SQSManager;

/**
 * Servlet implementation class FileUploadServlet
 */
@WebServlet("/uploadFile")
@MultipartConfig(fileSizeThreshold=1024*1024*10, 	// 10 MB 
	maxFileSize=1024*1024*50,      	// 50 MB
	maxRequestSize=1024*1024*100)   	// 100 MB
public class FileUploadServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    public FileUploadServlet() {
        super();
    }


	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		//https://www.codejava.net/coding/upload-files-to-database-servlet-jsp-mysql
		//TODO: check parameters is correct:  email
		String email = request.getParameter("email");
		String phoneNumber = request.getParameter("phone");
		RequestDispatcher view = null;
		
		//Upload to S3
		Part filePart = request.getPart("photo");
		
		view = request.getRequestDispatcher("error.html");
		
		if (filePart != null) {
			//Print out some information for debugging
			/*System.out.println(filePart.getName());
			System.out.println(filePart.getSubmittedFileName());
			System.out.println(filePart.getSize());
			System.out.println(filePart.getContentType());*/

			if (filePart.getContentType().equals("image/jpeg") || filePart.getContentType().equals("image/bmp")) {
				System.out.println("File is type image");
				
				S3Manager s3 = S3Manager.getInstance();
				String url  = s3.uploadObject(filePart);
				if (url != null) {	
					//Upload to Database
					try {
						RDSConnectionManager rds = RDSConnectionManager.getInstance();
						long id = rds.insertElement(phoneNumber,email,url);
						//Create message
						SQSManager sqs = SQSManager.getInstance();
						try {
							sqs.sendMessage(Long.toString(id));
							view = request.getRequestDispatcher("success.html");
							
							HttpSession session = request.getSession();
							session.setAttribute("email",email);
							Cookie cookie = new Cookie("email",email);
							cookie.setMaxAge(30*60); //30 mint
							response.addCookie(cookie);
							
						} catch (Exception e) {
							e.printStackTrace();
						}
					} catch (SQLException ex) {
						ex.printStackTrace();
						
					} catch (ClassNotFoundException ex) {
						ex.printStackTrace();
					}		
				}
			}
		}
		
		view.forward(request,response);
	}

}
