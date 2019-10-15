<%@ page language="java" contentType="text/html; charset=US-ASCII" pageEncoding="US-ASCII"%>
<%@ page import ="java.util.List"%>
<%@ page import ="java.util.ArrayList"%>
<%@ page import ="java.util.Map"%>

<!DOCTYPE html>
    <%
    	List<Map<String,String>> images = new ArrayList<Map<String,String>>();
    	if (request.getAttribute("images") != null) {
    		images = (List<Map<String,String>>) request.getAttribute("images");
    	}
    %>
<html>
<head>
<meta charset="ISO-8859-1">
<title>Gallery of Images</title>
</head>
<body>
	<h3>Gallery of images</h3>
<%
	if (images.isEmpty())
	{
		
		%><p>There is not any image to show</p><%
	} else {
		for (Map<String,String> image:images ) {
			String raw_url = image.get("s3_raw_url");
			String finished_url = image.get("s3_finished_url");
			
			if (raw_url != null) {
				%><img src="<%=raw_url%>" alt="Raw Image" height="200" width="200"><%
			} else {
				%><p> No raw image</p><%
			}
			if (finished_url != null) {
				%><img src="<%=finished_url%>" alt="Finished Image" height="200" width="200"><%
			} else {
				%><p> No finished image</p><%
			} 
		} 
	}

%>
	
</body>
</html>