FROM tomcat:10.1-jre21
COPY target/app.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
