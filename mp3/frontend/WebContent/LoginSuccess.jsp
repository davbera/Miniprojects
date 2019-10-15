<%@ page language="java" contentType="text/html; charset=US-ASCII" pageEncoding="US-ASCII"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=US-ASCII">
	<meta http-equiv="refresh" content="5;URL=admin">
	<title>Login Success Page</title>
</head>
<body>
	<%
	String user = (String) session.getAttribute("user");
	String userName = null;
	String sessionID = null;
	
	Cookie[] cookies = request.getCookies();
	
	if(cookies !=null){
		for(Cookie cookie : cookies){
			if(cookie.getName().equals("user")) 
				userName = cookie.getValue();
			if(cookie.getName().equals("JSESSIONID")) 
				sessionID = cookie.getValue();
		}
	}
	%>
	<h3>Login successful.</h3>
	<p>If you are not redirected to the admin page click in the following link</p>
	<a href="admin">Link to administration website</a>
	<br>
</body>
</html>