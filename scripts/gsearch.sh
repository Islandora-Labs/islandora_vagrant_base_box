#!/bin/bash

echo "Installing GSearch"

SHARED_DIR=$1

if [ -f "$SHARED_DIR/configs/variables" ]; then
  # shellcheck disable=SC1090
  . "$SHARED_DIR"/configs/variables
fi

# Dependencies
cd /tmp || exit
git clone -b 4.10.x --recursive https://github.com/discoverygarden/basic-solr-config.git
ln -s /var/lib/tomcat7 /usr/local/fedora/tomcat

# dgi_gsearch_extensions
cd /tmp || exit
git clone https://github.com/discoverygarden/dgi_gsearch_extensions.git
cd dgi_gsearch_extensions || exit
mvn -q package

# Build GSearch
cd /tmp || exit
git clone https://github.com/discoverygarden/gsearch.git
cd gsearch/FedoraGenericSearch || exit
ant buildfromsource

# Deploy GSearch
cp -v /tmp/gsearch/FgsBuild/fromsource/fedoragsearch.war /var/lib/tomcat7/webapps

# Sleep for 75 while Tomcat restart
echo "Sleeping for 75 while Tomcat stack restarts"
chown tomcat7:tomcat7 /var/lib/tomcat7/webapps/fedoragsearch.war
sed -i 's#JAVA_OPTS="-Djava.awt.headless=true -Xmx128m -XX:+UseConcMarkSweepGC"#JAVA_OPTS="-Djava.awt.headless=true -Xmx1024m -XX:MaxPermSize=256m -XX:+UseConcMarkSweepGC -Dkakadu.home=/usr/local/djatoka/bin/Linux-x86-64 -Djava.library.path=/usr/local/djatoka/lib/Linux-x86-64 -DLD_LIBRARY_PATH=/usr/local/djatoka/lib/Linux-x86-64"#g' /etc/default/tomcat7
service tomcat7 restart
sleep 75

# GSearch configurations
cd /var/lib/tomcat7/webapps/fedoragsearch/FgsConfig || exit
ant -f fgsconfig-basic.xml -Dlocal.FEDORA_HOME="$FEDORA_HOME" -DgsearchUser=fedoraAdmin -DgsearchPass=fedoraAdmin -DfinalConfigPath=/var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/classes -DlogFilePath="$FEDORA_HOME"/server/logs -DfedoraUser=fedoraAdmin -DfedoraPass=fedoraAdmin -DobjectStoreBase="$FEDORA_HOME"/data/objectStore -DindexDir="$SOLR_HOME"/collection1/data/index -DindexingDocXslt=foxmlToSolr -propertyfile fgsconfig-basic-for-islandora.properties




# Deploy dgi_gsearch_extensions
cp -v /tmp/dgi_gsearch_extensions/target/gsearch_extensions-0.1.2-jar-with-dependencies.jar /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/lib

# Solr & GSearch configurations
cp -v /tmp/basic-solr-config/conf/* "$SOLR_HOME"/collection1/conf
cp -Rv /tmp/basic-solr-config/islandora_transforms /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms
cp /tmp/basic-solr-config/foxmlToSolr.xslt /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/foxmlToSolr.xslt
cp /tmp/basic-solr-config/index.properties /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/index.properties
chown -hR tomcat7:tomcat7 "$SOLR_HOME"
chown -hR tomcat7:tomcat7 /var/lib/tomcat7/webapps/fedoragsearch

#Gsearch logging
cp "$SHARED_DIR"/configs/log4j.xml /usr/local/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes


# Restart Tomcat
chown tomcat7:tomcat7 /var/lib/tomcat7/webapps/fedoragsearch.war
service tomcat7 restart
