
FROM tomcat:10.1-jre21
<<<<<<< Updated upstream
# Remove the unused Canonical Pebble binary
RUN rm -f /usr/bin/pebble
=======

# Remove the unused Canonical Pebble binary
RUN rm -f /usr/bin/pebble

>>>>>>> Stashed changes
COPY target/app.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

