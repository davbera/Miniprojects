<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<title>Administration Page</title>
</head>
<body>
	<h3>Welcome Administrator!</h3>
<% 
	String message = (String) request.getAttribute("message");
	if (message != null) 
	{
		%><p><%=message%></p><%
	}
	
%>	
	<form action="dbbackup" method="post">
    	<input type="submit" value="Database backup" />
	</form>
	<form action="logout" method="post">
		<input type="submit" value="logout" >
	</form>
</body>
</html>