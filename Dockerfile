FROM tomcat:10.1-jre21
# Remove the unused Canonical Pebble binary
RUN rm -f /usr/bin/pebble
COPY target/app.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080

