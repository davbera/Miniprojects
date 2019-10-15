package filter;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebFilter("/AuthenticationFilter")
public class AuthenticationFilter implements Filter {
	private ServletContext context;
	
	public void init(FilterConfig fConfig) throws ServletException {
		this.context = fConfig.getServletContext();
	}
	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
		System.out.println("AuthenticationFilter.doFilter");
		
		HttpServletRequest req = (HttpServletRequest) request;
		HttpServletResponse res = (HttpServletResponse) response;
		
		String uri = req.getRequestURI();
		this.context.log("Requested Resource::"+uri);
		
		/*HttpSession session = req.getSession(false);
		
		if (session == null) {
			//if (!(uri.endsWith("admin.jsp") || uri.endsWith("admin"))) {
				chain.doFilter(request, response);
			} else {
				this.context.log("Unauthorized access request");
				res.sendRedirect("login");
			}
		} else if (session.getAttribute("user") != null) {
			chain.doFilter(request, response);
		} else {
			this.context.log("Unauthorized access request");
			res.sendRedirect("login");
		}*/
		
		chain.doFilter(request, response);
	}

	public void destroy() {
		//close any resources here
	}

}
