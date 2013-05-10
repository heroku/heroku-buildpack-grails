import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.ContextHandlerCollection;
import org.eclipse.jetty.server.handler.HandlerCollection;
import org.eclipse.jetty.webapp.WebAppContext;


public class Main {
	public static void main(String[] args) throws Exception {
		int port = Integer.parseInt(System.getProperty("jetty.port"));
		Server jetty = new Server(port);
		HandlerCollection hc = new HandlerCollection ();
		ContextHandlerCollection contextHandlerCollection = new ContextHandlerCollection();
		hc.setHandlers(new Handler[]{contextHandlerCollection});
		jetty.setHandler(hc);
		jetty.start();

		for(String arg : args) {
			WebAppContext webapp = new WebAppContext();
			webapp.setContextPath("/");
			webapp.setWar(arg);		
			
			contextHandlerCollection.addHandler(webapp);
			webapp.start();
		}
	}
}
