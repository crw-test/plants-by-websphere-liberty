#IMAGE: Get the base image for Liberty
FROM websphere-liberty:kernel

# Add Type 4 JDBC driver (Db2)
RUN mkdir /opt/ibm/wlp/usr/shared/resources/Db2
COPY wlp/usr/shared/resources/Db2/db2jcc4.jar /opt/ibm/wlp/usr/shared/resources/Db2/
USER root
RUN chown 1001:0 /opt/ibm/wlp/usr/shared/resources/Db2/*.jar
USER 1001

# Add Type 4 JDBC driver (MySQL)
#RUN mkdir /opt/ibm/wlp/usr/shared/resources/mysql
#COPY wlp/usr/shared/resources/mysql/mysql-connector-java-5.1.38.jar /opt/ibm/wlp/usr/shared/resources/mysql/
#USER root
#RUN chown 1001:0 /opt/ibm/wlp/usr/shared/resources/mysql/*.jar
#USER 1001

# CONFIG: Add in server.xml
COPY wlp/config/server.xml /config
USER root
RUN chown 1001:0 /config/server.xml
USER 1001

RUN configure.sh

ADD target/plants-by-websphere-jee6-mysql.ear /opt/ibm/wlp/usr/servers/defaultServer/apps
