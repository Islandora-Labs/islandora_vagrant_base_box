#!/bin/bash

SHARED_DIR=$1

# Apache configuration file
export APACHE_CONFIG_FILE=/etc/apache2/sites-enabled/000-default.conf


if [ -f "$SHARED_DIR/configs/variables" ]; then
# shellcheck source=/dev/null.
  . "$SHARED_DIR"/configs/variables
fi

echo "Installing Cantaloupe"

# Setup install path and download Cantaloupe
if [ ! -d "$CANTALOUPE_HOME" ]; then
  mkdir  -p "$CANTALOUPE_HOME"
fi
if [ ! -d "$CANTALOUPE_LOGS" ]; then
  mkdir  -p "$CANTALOUPE_LOGS"
fi
if [ ! -d "$CANTALOUPE_CACHE" ]; then
  mkdir  -p "$CANTALOUPE_CACHE"
fi

if [ ! -f "$DOWNLOAD_DIR/Cantaloupe.zip" ]; then
  echo "Downloading Cantaloupe"
  wget -q -O "$DOWNLOAD_DIR/Cantaloupe.zip" "https://github.com/medusa-project/cantaloupe/releases/download/v$CANTALOUPE_VERSION/Cantaloupe-$CANTALOUPE_VERSION.zip"
fi

cd /tmp || exit
cp "$DOWNLOAD_DIR/Cantaloupe.zip" /tmp
unzip Cantaloupe.zip
cd Cantaloupe-"$CANTALOUPE_VERSION" || exit
mv -v ./* "$CANTALOUPE_HOME"

# Deploy Cantaloupe
cp -v "$CANTALOUPE_HOME"/Cantaloupe-"$CANTALOUPE_VERSION".war /var/lib/tomcat7/webapps/cantaloupe.war
chown tomcat7:tomcat7 /var/lib/tomcat7/webapps/cantaloupe.war

# Libraries
cp "$SHARED_DIR"/configs/cantaloupe.properties "$CANTALOUPE_HOME"
cp "$SHARED_DIR"/configs/cantaloupe.delegates.rb "$CANTALOUPE_HOME"/delegates.rb

chown -R tomcat7:tomcat7 "$CANTALOUPE_HOME"
chown -R tomcat7:tomcat7 "$CANTALOUPE_LOGS"
chown -R tomcat7:tomcat7 "$CANTALOUPE_CACHE"

# Make tomcat/VM aware of cantaloup's config 
# shellcheck disable=SC2016
echo 'JAVA_OPTS="${JAVA_OPTS} -Dcantaloupe.config=/usr/local/cantaloupe/cantaloupe.properties -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true"' >> /etc/default/tomcat7

# add cantaloupe proxy pass 
if [ "$(grep -c "iiif" $APACHE_CONFIG_FILE)" -eq 0 ]; then

read -d '' APACHE_CONFIG << APACHE_CONFIG_TEXT
	ProxyPass /iiif/2 http://localhost:8080/cantaloupe/iiif/2
	ProxyPassReverse /iiif/2 http://localhost:8080/cantaloupe/iiif/2

	RequestHeader set X-Forwarded-Port 8000
APACHE_CONFIG_TEXT

sed -i "/<\/VirtualHost>/i $(echo "|	$APACHE_CONFIG" | tr '\n' '|')" $APACHE_CONFIG_FILE
tr '|' '\n' < $APACHE_CONFIG_FILE > $APACHE_CONFIG_FILE.t 2> /dev/null; mv $APACHE_CONFIG_FILE{.t,}

fi

#OpenJPEG from source
apt-get -y update
apt-get install -y openjpeg-tools libopenjpeg2 liblcms2-dev  libtiff-dev libpng-dev libz-dev 
apt-get install -y cmake
cd "$DOWNLOAD_DIR" || exit
git clone https://github.com/uclouvain/openjpeg
cd openjpeg/ || exit
mkdir build
cd build || exit
cmake .. -DCMAKE_BUILD_TYPE=Release
make
make install
ldconfig

# Sleep for 60 while Tomcat restart
echo "Sleeping for 60 while Tomcat stack restarts"
service tomcat7 restart
sleep 60
service apache2 restart
sleep 5
